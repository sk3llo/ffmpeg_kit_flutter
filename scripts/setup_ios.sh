#!/bin/bash
#
# Downloads the prebuilt FFmpegKit iOS frameworks and installs them into
# ./Frameworks as .xcframeworks. Run from the pod root (the plugin's `ios/`
# directory) — the podspec's prepare_command does exactly that.
#
# Robustness (see issue #88 — "'ffmpegkit/FFmpegKitConfig.h' file not found"):
#   * Atomic install: the frameworks appear in ./Frameworks only after a fully
#     successful download + extraction + conversion + sanity check. A failure
#     never leaves a half-populated ./Frameworks — which is what used to make the
#     next `pod install` skip setup and produce a confusing "header not found"
#     build error much later.
#   * curl uses --fail/--retry so HTTP errors (404, proxy pages) and flaky
#     networks fail loudly here instead of silently saving an error page as a zip.
#   * The archive is verified before we trust it, and all 8 expected frameworks
#     must be present afterwards.
#   * Restricted networks (behind a firewall / in a blocked region) can point
#     FFMPEG_KIT_IOS_URL at a reachable mirror of the release zip.
#
set -euo pipefail

VERSION="8.1.2"
VARIANT="video"
DEFAULT_URL="https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/${VERSION}-${VARIANT}/ffmpeg-kit-ios-${VARIANT}-${VERSION}.zip"
IOS_URL="${FFMPEG_KIT_IOS_URL:-$DEFAULT_URL}"

FRAMEWORKS="ffmpegkit libavcodec libavdevice libavfilter libavformat libavutil libswresample libswscale"

# Self-healing / idempotent: if the frameworks are already installed, do nothing.
# The podspec guard checks the same marker, but re-checking here keeps the script
# safe to run manually and safe to re-run after a previous failure.
if [ -d "Frameworks/ffmpegkit.xcframework" ]; then
  echo "[ffmpeg_kit_flutter] iOS frameworks already present — skipping download."
  exit 0
fi

WORK="$(mktemp -d "${TMPDIR:-/tmp}/ffmpegkit-ios.XXXXXX")"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

fail() {
  {
    echo ""
    echo "======================================================================"
    echo "[ffmpeg_kit_flutter] ERROR: could not set up the iOS frameworks."
    echo "  $1"
    echo ""
    echo "The prebuilt FFmpegKit frameworks are downloaded at build time from:"
    echo "  $IOS_URL"
    echo ""
    echo "If your network cannot reach GitHub release assets (e.g. behind a"
    echo "corporate firewall or in a restricted region), either:"
    echo ""
    echo "  1. Mirror the zip somewhere reachable and set FFMPEG_KIT_IOS_URL"
    echo "     before installing pods:"
    echo "       export FFMPEG_KIT_IOS_URL=\"https://your-mirror/ffmpeg-kit-ios-${VARIANT}-${VERSION}.zip\""
    echo "       cd ios && pod install"
    echo ""
    echo "  2. Or download the zip manually and re-run this script from the"
    echo "     plugin's ios/ directory:"
    echo "       ../scripts/setup_ios.sh"
    echo "======================================================================"
  } >&2
  exit 1
}

# Build curl args, feature-detecting --retry-all-errors (curl >= 7.71).
CURL_ARGS=(-fL --retry 3 --retry-delay 2 --connect-timeout 30)
if curl --help all 2>/dev/null | grep -q -- '--retry-all-errors'; then
  CURL_ARGS+=(--retry-all-errors)
fi

echo "[ffmpeg_kit_flutter] Downloading iOS frameworks ($VARIANT $VERSION)..."
echo "[ffmpeg_kit_flutter]   $IOS_URL"
if ! curl "${CURL_ARGS[@]}" -o "$WORK/frameworks.zip" "$IOS_URL"; then
  fail "The download failed (see the curl output above)."
fi

# Reject empty / truncated / non-zip payloads before trusting them.
[ -s "$WORK/frameworks.zip" ] || fail "The downloaded file is empty."
if ! unzip -tq "$WORK/frameworks.zip" >/dev/null 2>&1; then
  fail "The downloaded file is not a valid zip (likely a partial download or an error page)."
fi

mkdir -p "$WORK/extract"
unzip -oq "$WORK/frameworks.zip" -d "$WORK/extract"
rm -rf "$WORK/extract/__MACOSX"

# Verify the archive actually contained the fat frameworks we expect.
for FW in $FRAMEWORKS; do
  [ -d "$WORK/extract/${FW}.framework" ] || \
    fail "The archive is missing ${FW}.framework — it may be corrupt or the wrong build."
done

# Delete bitcode from all frameworks.
for FW in $FRAMEWORKS; do
  BIN="$WORK/extract/${FW}.framework/${FW}"
  [ -f "$BIN" ] && xcrun bitcode_strip -r "$BIN" -o "$BIN"
done

#
# Convert each fat .framework into an .xcframework that exposes a real
# arm64 iOS-simulator slice.
#
# The released frameworks are fat Mach-O bundles containing:
#   x86_64  -> iOS simulator (platform 7)
#   arm64   -> iOS device    (platform 2)
#   arm64e  -> iOS device    (platform 2)
#
# A fat framework cannot hold both a device-arm64 and a simulator-arm64 slice
# (same CPU type), which is why arm64 had to be excluded for the simulator.
# Apple Silicon simulators on Xcode 26 / iOS 26+ require a native arm64
# simulator slice, so we split each framework into two .xcframework variants:
#   ios-arm64                   (device; arm64e is dropped, see #164)
#   ios-arm64_x86_64-simulator  (simulator: x86_64 + arm64 retagged via vtool)
#
# The arm64 simulator slice is produced by retagging the device arm64 slice's
# build-version platform from iOS (2) to iOS-Simulator (7). FFmpeg is plain C
# with no platform-conditional linkage, so the instructions are identical and
# the retagged slice runs natively on Apple Silicon simulators.
#
# BASE is the directory holding the fat .framework inputs; the resulting
# .xcframework is written alongside them and later moved into ./Frameworks.
#
convert_to_xcframework() {
  local FW="$1"
  local BASE="$2"
  local DIR="${BASE}/${FW}.framework"
  local BIN="${DIR}/${FW}"
  [ -d "$DIR" ] || return 0

  local ARCHS
  ARCHS=$(lipo -archs "$BIN")

  # Read the device deployment target / sdk so vtool reproduces them.
  local MINOS SDK
  MINOS=$(otool -l -arch arm64 "$BIN" 2>/dev/null | awk '/LC_BUILD_VERSION/{b=1} b&&/minos/{print $2; exit}')
  SDK=$(otool -l -arch arm64 "$BIN" 2>/dev/null | awk '/LC_BUILD_VERSION/{b=1} b&&/sdk/{print $2; exit}')
  [ -n "$MINOS" ] || MINOS="14.0"
  [ -n "$SDK" ] || SDK="$MINOS"

  local STAGE="${BASE}/.xc_tmp/${FW}"
  rm -rf "$STAGE"
  mkdir -p "$STAGE"
  cp -R "$DIR" "$STAGE/device.framework"
  cp -R "$DIR" "$STAGE/sim.framework"
  # xcodebuild requires the inner framework names to match the binary name.
  mv "$STAGE/device.framework" "$STAGE/device/${FW}.framework" 2>/dev/null || { mkdir -p "$STAGE/device"; mv "$STAGE/device.framework" "$STAGE/device/${FW}.framework"; }
  mkdir -p "$STAGE/sim"
  mv "$STAGE/sim.framework" "$STAGE/sim/${FW}.framework"

  # --- Device slice: arm64 ONLY. arm64e is deliberately dropped: App Store
  # apps run as arm64 (third-party arm64e needs a special entitlement), and
  # App Store validation rejects arm64e slices built with pre-iOS-26 SDKs (#164).
  lipo "$BIN" -thin arm64 -output "$STAGE/arm64.dylib"
  lipo -create "$STAGE/arm64.dylib" -output "$STAGE/device/${FW}.framework/${FW}"

  # --- Simulator slice: x86_64 (+ arm64 retagged to simulator) ---
  local SIM_ARGS=()
  if echo "$ARCHS" | tr ' ' '\n' | grep -qx "x86_64"; then
    lipo "$BIN" -thin x86_64 -output "$STAGE/x86_64.dylib"
    SIM_ARGS+=("$STAGE/x86_64.dylib")
  fi
  if echo "$ARCHS" | tr ' ' '\n' | grep -qx "arm64"; then
    lipo "$BIN" -thin arm64 -output "$STAGE/arm64-dev.dylib"
    vtool -arch arm64 -set-build-version 7 "$MINOS" "$SDK" -replace \
      -output "$STAGE/arm64-sim.dylib" "$STAGE/arm64-dev.dylib"
    SIM_ARGS+=("$STAGE/arm64-sim.dylib")
  fi
  lipo -create "${SIM_ARGS[@]}" -output "$STAGE/sim/${FW}.framework/${FW}"

  # --- Assemble the xcframework ---
  rm -rf "${BASE}/${FW}.xcframework"
  xcodebuild -create-xcframework \
    -framework "$STAGE/device/${FW}.framework" \
    -framework "$STAGE/sim/${FW}.framework" \
    -output "${BASE}/${FW}.xcframework"

  rm -rf "$DIR" "$STAGE"
}

echo "[ffmpeg_kit_flutter] Building xcframeworks..."
for FW in $FRAMEWORKS; do
  convert_to_xcframework "$FW" "$WORK/extract"
done
rm -rf "$WORK/extract/.xc_tmp"

# Verify every xcframework was produced before we touch ./Frameworks.
for FW in $FRAMEWORKS; do
  [ -d "$WORK/extract/${FW}.xcframework" ] || \
    fail "Failed to build ${FW}.xcframework (Xcode command line tools required)."
done

# --- Atomic install: only now do we populate ./Frameworks ---
rm -rf Frameworks
mkdir -p Frameworks
for FW in $FRAMEWORKS; do
  mv "$WORK/extract/${FW}.xcframework" "Frameworks/${FW}.xcframework"
done

echo "[ffmpeg_kit_flutter] iOS frameworks installed successfully."
