#!/bin/bash
#
# Downloads the prebuilt FFmpegKit macOS frameworks and installs them into
# ./Frameworks. Run from the pod root (the plugin's `macos/` directory) — the
# podspec's prepare_command does exactly that.
#
# Same robustness contract as setup_ios.sh (see issue #88):
#   * Atomic install — ./Frameworks is only populated after a fully successful
#     download + extraction + sanity check, so a failure never leaves a broken
#     half-populated directory behind (which is what made the next `pod install`
#     skip setup and produce a confusing "header not found" build error).
#   * curl --fail/--retry surfaces network errors here instead of later.
#   * FFMPEG_KIT_MACOS_URL overrides the download URL for restricted networks.
#   * FFMPEG_KIT_MACOS_SHA256, when set, is the SHA-256 the downloaded zip must
#     have, whichever URL it came from. On a mismatch nothing is unpacked.
#
# Zips from 8.1.3 on carry <name>.framework.dSYM beside each framework. They
# are installed beside the frameworks, where CocoaPods finds a vendored
# framework's dSYM and copies it into builds and archives. A zip without dSYMs
# installs as before.
#
set -euo pipefail

VERSION="8.1.2"
VARIANT="https"
DEFAULT_URL="https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/${VERSION}-${VARIANT}/ffmpeg-kit-macos-${VARIANT}-${VERSION}.zip"
MACOS_URL="${FFMPEG_KIT_MACOS_URL:-$DEFAULT_URL}"
# Lower-cased, without the "sha256:" prefix GitHub prints in front of a digest.
MACOS_SHA256="$(printf '%s' "${FFMPEG_KIT_MACOS_SHA256:-}" | tr '[:upper:]' '[:lower:]')"
MACOS_SHA256="${MACOS_SHA256#sha256:}"

FRAMEWORKS="ffmpegkit libavcodec libavdevice libavfilter libavformat libavutil libswresample libswscale"

# Self-healing / idempotent.
if [ -d "Frameworks/ffmpegkit.framework" ]; then
  echo "[ffmpeg_kit_flutter] macOS frameworks already present — skipping download."
  exit 0
fi

WORK="$(mktemp -d "${TMPDIR:-/tmp}/ffmpegkit-macos.XXXXXX")"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

fail() {  # <reason> [no-network-help]
  {
    echo ""
    echo "======================================================================"
    echo "[ffmpeg_kit_flutter] ERROR: could not set up the macOS frameworks."
    echo "  $1"
    echo ""
    echo "The prebuilt FFmpegKit frameworks are downloaded at build time from:"
    echo "  $MACOS_URL"
    if [ "${2:-}" != "no-network-help" ]; then
      echo ""
      echo "If your network cannot reach GitHub release assets, either mirror the"
      echo "zip and set FFMPEG_KIT_MACOS_URL before installing pods:"
      echo "  export FFMPEG_KIT_MACOS_URL=\"https://your-mirror/ffmpeg-kit-macos-${VARIANT}-${VERSION}.zip\""
      echo "  cd macos && pod install"
      echo "or download it manually and re-run ../scripts/setup_macos.sh."
    fi
    echo "======================================================================"
  } >&2
  exit 1
}

if [ -n "$MACOS_SHA256" ] && ! printf '%s' "$MACOS_SHA256" | grep -qE '^[0-9a-f]{64}$'; then
  fail "FFMPEG_KIT_MACOS_SHA256 is not a SHA-256 digest (64 hexadecimal characters)." no-network-help
fi

sha256_of() {  # <file>; prints the digest in lower-case hex
  local OUT
  OUT="$(shasum -a 256 "$1" 2>/dev/null)" || OUT="$(sha256sum "$1" 2>/dev/null)" ||
    OUT="$(openssl dgst -sha256 -r "$1" 2>/dev/null)" || return 1
  printf '%s' "${OUT%% *}" | tr '[:upper:]' '[:lower:]'
}

CURL_ARGS=(-fL --retry 3 --retry-delay 2 --connect-timeout 30)
if curl --help all 2>/dev/null | grep -q -- '--retry-all-errors'; then
  CURL_ARGS+=(--retry-all-errors)
fi

echo "[ffmpeg_kit_flutter] Downloading macOS frameworks ($VARIANT $VERSION)..."
echo "[ffmpeg_kit_flutter]   $MACOS_URL"
if ! curl "${CURL_ARGS[@]}" -o "$WORK/frameworks.zip" "$MACOS_URL"; then
  fail "The download failed (see the curl output above)."
fi

[ -s "$WORK/frameworks.zip" ] || fail "The downloaded file is empty."
if [ -n "$MACOS_SHA256" ]; then
  ACTUAL_SHA256="$(sha256_of "$WORK/frameworks.zip")" ||
    fail "Could not compute the downloaded file's SHA-256 (tried shasum, sha256sum and openssl)." no-network-help
  if [ "$ACTUAL_SHA256" != "$MACOS_SHA256" ]; then
    fail "The downloaded file's SHA-256 does not match FFMPEG_KIT_MACOS_SHA256.
    expected: $MACOS_SHA256
    actual:   $ACTUAL_SHA256" no-network-help
  fi
  echo "[ffmpeg_kit_flutter]   SHA-256 verified: $ACTUAL_SHA256"
fi
if ! unzip -tq "$WORK/frameworks.zip" >/dev/null 2>&1; then
  fail "The downloaded file is not a valid zip (likely a partial download or an error page)."
fi

mkdir -p "$WORK/extract"
unzip -oq "$WORK/frameworks.zip" -d "$WORK/extract"
rm -rf "$WORK/extract/__MACOSX"
# Drop AppleDouble files (._*). A zip made on macOS without --norsrc stores
# each file's extended attributes as a ._<name> file next to it, and unzip
# writes those out as real files. In a framework root they are unsealed
# contents, so codesign refuses to sign the framework and the app's CodeSign
# step fails with "code object is not signed at all" (issue #170).
find "$WORK/extract" -name '._*' -type f -delete

# Verify all expected frameworks are present.
for FW in $FRAMEWORKS; do
  [ -d "$WORK/extract/${FW}.framework" ] || \
    fail "The archive is missing ${FW}.framework — it may be corrupt or the wrong build."
done

# Delete bitcode from all frameworks (required for App Store submission).
for FW in $FRAMEWORKS; do
  BIN="$WORK/extract/${FW}.framework/${FW}"
  [ -f "$BIN" ] && xcrun bitcode_strip -r "$BIN" -o "$BIN"
done

# --- Atomic install ---
rm -rf Frameworks
mkdir -p Frameworks
for FW in $FRAMEWORKS; do
  mv "$WORK/extract/${FW}.framework" "Frameworks/${FW}.framework"
  if [ -d "$WORK/extract/${FW}.framework.dSYM" ]; then
    mv "$WORK/extract/${FW}.framework.dSYM" "Frameworks/${FW}.framework.dSYM"
  fi
done

echo "[ffmpeg_kit_flutter] macOS frameworks installed successfully."
