#!/bin/bash
set -e

# Download and unzip iOS framework
IOS_URL="https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/8.1.1-audio/ffmpeg-kit-ios-audio-8.1.1.zip"
mkdir -p Frameworks
curl -L $IOS_URL -o frameworks.zip
unzip -o frameworks.zip -d Frameworks
rm frameworks.zip
rm -rf Frameworks/__MACOSX

FRAMEWORKS="ffmpegkit libavcodec libavdevice libavfilter libavformat libavutil libswresample libswscale"

# Delete bitcode from all frameworks
for FW in $FRAMEWORKS; do
  BIN="Frameworks/${FW}.framework/${FW}"
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
#   ios-arm64_arm64e            (device, untouched)
#   ios-arm64_x86_64-simulator  (simulator: x86_64 + arm64 retagged via vtool)
#
# The arm64 simulator slice is produced by retagging the device arm64 slice's
# build-version platform from iOS (2) to iOS-Simulator (7). FFmpeg is plain C
# with no platform-conditional linkage, so the instructions are identical and
# the retagged slice runs natively on Apple Silicon simulators.
#
convert_to_xcframework() {
  local FW="$1"
  local DIR="Frameworks/${FW}.framework"
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

  local STAGE="Frameworks/.xc_tmp/${FW}"
  rm -rf "$STAGE"
  mkdir -p "$STAGE"
  cp -R "$DIR" "$STAGE/device.framework"
  cp -R "$DIR" "$STAGE/sim.framework"
  # xcodebuild requires the inner framework names to match the binary name.
  mv "$STAGE/device.framework" "$STAGE/device/${FW}.framework" 2>/dev/null || { mkdir -p "$STAGE/device"; mv "$STAGE/device.framework" "$STAGE/device/${FW}.framework"; }
  mkdir -p "$STAGE/sim"
  mv "$STAGE/sim.framework" "$STAGE/sim/${FW}.framework"

  # --- Device slice: arm64 (+ arm64e if present) ---
  local DEV_ARGS=()
  for A in arm64 arm64e; do
    if echo "$ARCHS" | tr ' ' '\n' | grep -qx "$A"; then
      lipo "$BIN" -thin "$A" -output "$STAGE/${A}.dylib"
      DEV_ARGS+=("$STAGE/${A}.dylib")
    fi
  done
  lipo -create "${DEV_ARGS[@]}" -output "$STAGE/device/${FW}.framework/${FW}"

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
  rm -rf "Frameworks/${FW}.xcframework"
  xcodebuild -create-xcframework \
    -framework "$STAGE/device/${FW}.framework" \
    -framework "$STAGE/sim/${FW}.framework" \
    -output "Frameworks/${FW}.xcframework"

  rm -rf "$DIR" "$STAGE"
}

for FW in $FRAMEWORKS; do
  convert_to_xcframework "$FW"
done

rm -rf Frameworks/.xc_tmp
