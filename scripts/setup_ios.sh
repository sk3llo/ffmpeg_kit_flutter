#!/bin/bash

# Download and unzip iOS framework
IOS_URL="https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/8.0.0-full-gpl/ffmpeg-kit-ios-full-gpl-8.0.0.zip"
mkdir -p Frameworks
curl -L $IOS_URL -o frameworks.zip
unzip -o frameworks.zip -d Frameworks
rm frameworks.zip

# Delete bitcode from all frameworks
xcrun bitcode_strip -r Frameworks/ffmpegkit.framework/ffmpegkit -o Frameworks/ffmpegkit.framework/ffmpegkit
xcrun bitcode_strip -r Frameworks/libavcodec.framework/libavcodec -o Frameworks/libavcodec.framework/libavcodec
xcrun bitcode_strip -r Frameworks/libavdevice.framework/libavdevice -o Frameworks/libavdevice.framework/libavdevice
xcrun bitcode_strip -r Frameworks/libavfilter.framework/libavfilter -o Frameworks/libavfilter.framework/libavfilter
xcrun bitcode_strip -r Frameworks/libavformat.framework/libavformat -o Frameworks/libavformat.framework/libavformat
xcrun bitcode_strip -r Frameworks/libavutil.framework/libavutil -o Frameworks/libavutil.framework/libavutil
xcrun bitcode_strip -r Frameworks/libswresample.framework/libswresample -o Frameworks/libswresample.framework/libswresample
xcrun bitcode_strip -r Frameworks/libswscale.framework/libswscale -o Frameworks/libswscale.framework/libswscale

# Convert each framework to XCFramework with device + simulator variants
# iOS 26+ simulators on Apple Silicon require arm64, but the vendored
# frameworks ship arm64 built for iOS device platform, not simulator.
# Xcode rejects linking device binaries into simulator targets.
# Fix: create .xcframework with two variants — device unchanged,
# simulator variant has arm64 platform patched to IOSSIMULATOR.
for fw in Frameworks/*.framework; do
  fwname=$(basename "$fw" .framework)
  fwpath="$fw/$fwname"

  # Thin fat binary into per-architecture slices
  lipo "$fwpath" -thin arm64  -output "/tmp/${fwname}_arm64"
  lipo "$fwpath" -thin x86_64 -output "/tmp/${fwname}_x86_64"
  lipo "$fwpath" -thin arm64e -output "/tmp/${fwname}_arm64e"

  # Convert arm64 slice from IOS (platform 2) to IOSSIMULATOR (platform 7)
  # Keeps minos=12.1 and sdk=18.5 to match original build
  xcrun vtool -set-build-version 7 12.1 18.5 -replace \
    -output "/tmp/${fwname}_arm64_sim" "/tmp/${fwname}_arm64"

  # Device variant: keep arm64 (IOS) + arm64e (IOS) slices
  devdir="XCFramework/tmp/ios-arm64/$fwname.framework"
  mkdir -p "$devdir"
  cp -R "$fw/" "$devdir/"
  if [ -f "/tmp/${fwname}_arm64e" ]; then
    lipo "/tmp/${fwname}_arm64" "/tmp/${fwname}_arm64e" \
      -create -output "$devdir/$fwname"
  else
    cp "/tmp/${fwname}_arm64" "$devdir/$fwname"
  fi

  # Simulator variant: combined converted arm64 (IOSSIMULATOR) + original x86_64 (IOSSIMULATOR)
  simdir="XCFramework/tmp/ios-arm64_x86_64-simulator/$fwname.framework"
  mkdir -p "$simdir"
  cp -R "$fw/" "$simdir/"
  lipo "/tmp/${fwname}_arm64_sim" "/tmp/${fwname}_x86_64" \
    -create -output "$simdir/$fwname"
  # Info.plist must declare iPhoneSimulator platform for simulator variant
  sed -i '' 's/iPhoneOS/iPhoneSimulator/g' "$simdir/Info.plist"

  # Create final .xcframework containing both variants
  xcodebuild -create-xcframework \
    -framework "$devdir" \
    -framework "$simdir" \
    -output "Frameworks/$fwname.xcframework" 2>&1

  rm -f "/tmp/${fwname}_arm64" "/tmp/${fwname}_arm64e" \
        "/tmp/${fwname}_x86_64" "/tmp/${fwname}_arm64_sim"
  rm -rf "XCFramework/tmp"
done
# Remove original .framework dirs, keep only .xcframework
rm -rf Frameworks/*.framework