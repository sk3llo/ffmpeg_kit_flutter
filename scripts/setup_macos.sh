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
#
set -euo pipefail

VERSION="8.1.2"
VARIANT="full"
DEFAULT_URL="https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/${VERSION}-${VARIANT}/ffmpeg-kit-macos-${VARIANT}-${VERSION}.zip"
MACOS_URL="${FFMPEG_KIT_MACOS_URL:-$DEFAULT_URL}"

FRAMEWORKS="ffmpegkit libavcodec libavdevice libavfilter libavformat libavutil libswresample libswscale"

# Self-healing / idempotent.
if [ -d "Frameworks/ffmpegkit.framework" ]; then
  echo "[ffmpeg_kit_flutter] macOS frameworks already present — skipping download."
  exit 0
fi

WORK="$(mktemp -d "${TMPDIR:-/tmp}/ffmpegkit-macos.XXXXXX")"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

fail() {
  {
    echo ""
    echo "======================================================================"
    echo "[ffmpeg_kit_flutter] ERROR: could not set up the macOS frameworks."
    echo "  $1"
    echo ""
    echo "The prebuilt FFmpegKit frameworks are downloaded at build time from:"
    echo "  $MACOS_URL"
    echo ""
    echo "If your network cannot reach GitHub release assets, either mirror the"
    echo "zip and set FFMPEG_KIT_MACOS_URL before installing pods:"
    echo "  export FFMPEG_KIT_MACOS_URL=\"https://your-mirror/ffmpeg-kit-macos-${VARIANT}-${VERSION}.zip\""
    echo "  cd macos && pod install"
    echo "or download it manually and re-run ../scripts/setup_macos.sh."
    echo "======================================================================"
  } >&2
  exit 1
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
if ! unzip -tq "$WORK/frameworks.zip" >/dev/null 2>&1; then
  fail "The downloaded file is not a valid zip (likely a partial download or an error page)."
fi

mkdir -p "$WORK/extract"
unzip -oq "$WORK/frameworks.zip" -d "$WORK/extract"
rm -rf "$WORK/extract/__MACOSX"

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
done

echo "[ffmpeg_kit_flutter] macOS frameworks installed successfully."
