#!/bin/bash
#
# Regression test for issue #170: setup_macos.sh and setup_ios.sh must install
# frameworks that sign the way CocoaPods and Xcode sign them, even when the
# release zip carries AppleDouble (._*) metadata.
#
#   scripts/tests/test_apple_setup.sh
#
# It runs offline. It builds 8 tiny frameworks shaped like the real ones
# (versioned bundles for macOS, fat device + simulator bundles for iOS), packs
# them the three ways a zip comes out of macOS, and runs the real setup script
# on each zip through FFMPEG_KIT_{MACOS,IOS}_URL=file://...:
#   clean   ditto -c -k --norsrc         how release zips must be made
#   inline  ditto -c -k                  how the 8.1.1 and 8.1.2 zips were made
#   macosx  ditto -c -k --sequesterRsrc  a __MACOSX/ folder, like 8.0.0
# The installed frameworks must contain no ._ files and pass
# check_apple_zip.sh.
#
# Self-checks keep the test honest: the inline zip must really contain ._
# entries, and check_apple_zip.sh must reject it for the reason users hit
# (macOS: the frameworks do not sign; iOS: ._ files get sealed into the
# signature). Otherwise the test could not tell a fixed setup script from a
# broken one.
#
# Needs macOS with Xcode (clang, lipo, vtool, xcodebuild, codesign).
#
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS="$(cd "$HERE/.." && pwd)"
CHECK="$SCRIPTS/check_apple_zip.sh"
FRAMEWORKS="ffmpegkit libavcodec libavdevice libavfilter libavformat libavutil libswresample libswscale"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/test-apple-setup.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

FAILURES=0
pass() { echo "ok    $1"; }
fail() { echo "FAIL  $1"; FAILURES=$((FAILURES + 1)); }
indent() { sed 's/^/      /'; }

plist() {  # <path> <executable> <platform>
  cat > "$1" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>$2</string>
  <key>CFBundleIdentifier</key><string>com.example.test.$2</string>
  <key>CFBundleName</key><string>$2</string>
  <key>CFBundlePackageType</key><string>FMWK</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>CFBundleSupportedPlatforms</key><array><string>$3</string></array>
</dict></plist>
PLIST
}

make_macos_tree() {  # <out>
  local OUT="$1" FW D
  for FW in $FRAMEWORKS; do
    D="$OUT/$FW.framework"
    mkdir -p "$D/Versions/A/Headers" "$D/Versions/A/Resources"
    printf 'int %s_test(void) { return 0; }\n' "$FW" > "$WORK/$FW.c"
    xcrun --sdk macosx clang -arch arm64 -arch x86_64 -mmacosx-version-min=10.15 \
      -dynamiclib -install_name "@rpath/$FW.framework/Versions/A/$FW" \
      -o "$D/Versions/A/$FW" "$WORK/$FW.c"
    printf 'int %s_test(void);\n' "$FW" > "$D/Versions/A/Headers/$FW.h"
    plist "$D/Versions/A/Resources/Info.plist" "$FW" MacOSX
    ln -s A "$D/Versions/Current"
    ln -s Versions/Current/Headers "$D/Headers"
    ln -s Versions/Current/Resources "$D/Resources"
    ln -s "Versions/Current/$FW" "$D/$FW"
  done
}

make_ios_tree() {  # <out>
  local OUT="$1" FW D
  for FW in $FRAMEWORKS; do
    D="$OUT/$FW.framework"
    mkdir -p "$D/Headers"
    printf 'int %s_test(void) { return 0; }\n' "$FW" > "$WORK/$FW.c"
    xcrun --sdk iphoneos clang -arch arm64 -miphoneos-version-min=14.0 -dynamiclib \
      -install_name "@rpath/$FW.framework/$FW" -o "$WORK/$FW-device" "$WORK/$FW.c"
    xcrun --sdk iphonesimulator clang -arch x86_64 -mios-simulator-version-min=14.0 -dynamiclib \
      -install_name "@rpath/$FW.framework/$FW" -o "$WORK/$FW-sim" "$WORK/$FW.c"
    lipo -create "$WORK/$FW-device" "$WORK/$FW-sim" -output "$D/$FW"
    printf 'int %s_test(void);\n' "$FW" > "$D/Headers/$FW.h"
    plist "$D/Info.plist" "$FW" iPhoneOS
  done
}

count_entries() {  # <zip> <regex>
  unzip -Z1 "$1" | grep -cE "$2" || true
}

run_setup() {  # <platform> <case>; installs into $WORK/run-<platform>-<case>/pod
  local P="$1" C="$2" R="$WORK/run-$1-$2"
  rm -rf "$R"
  mkdir -p "$R/pod"
  if [ "$P" = "macos" ]; then
    (cd "$R/pod" && FFMPEG_KIT_MACOS_URL="file://$WORK/$P-$C.zip" /bin/bash "$SCRIPTS/setup_macos.sh") > "$R/log" 2>&1
  else
    (cd "$R/pod" && FFMPEG_KIT_IOS_URL="file://$WORK/$P-$C.zip" /bin/bash "$SCRIPTS/setup_ios.sh") > "$R/log" 2>&1
  fi
}

for P in macos ios; do
  T="$WORK/tree-$P"
  mkdir -p "$T"
  if [ "$P" = "macos" ]; then make_macos_tree "$T"; else make_ios_tree "$T"; fi
  # Files on a build machine carry extended attributes (com.apple.provenance
  # on every file a recent macOS creates). Give ditto some to store.
  find "$T" -mindepth 1 ! -type l -exec xattr -w com.ffmpegkit.test 1 {} \;
  ditto -c -k --norsrc --noextattr --noacl "$T" "$WORK/$P-clean.zip"
  ditto -c -k "$T" "$WORK/$P-inline.zip"
  ditto -c -k --sequesterRsrc "$T" "$WORK/$P-macosx.zip"

  # Self-checks.
  N=$(count_entries "$WORK/$P-inline.zip" '(^|/)\._')
  if [ "$N" -gt 0 ]; then pass "$P: the inline zip carries $N ._ entries"
  else fail "$P: ditto -c -k stored no ._ entries, so this test proves nothing"; fi
  N=$(count_entries "$WORK/$P-macosx.zip" '^__MACOSX/')
  if [ "$N" -gt 0 ]; then pass "$P: the macosx zip carries $N __MACOSX/ entries"
  else fail "$P: ditto --sequesterRsrc stored no __MACOSX/ entries"; fi
  N=$(count_entries "$WORK/$P-clean.zip" '(^|/)(\._|__MACOSX)')
  if [ "$N" -eq 0 ]; then pass "$P: the clean zip carries no metadata entries"
  else fail "$P: ditto --norsrc stored $N metadata entries"; fi

  if "$CHECK" --platform "$P" "$WORK/$P-clean.zip" > "$WORK/$P-clean.check" 2>&1; then
    pass "$P: check_apple_zip.sh accepts the clean zip"
  else
    fail "$P: check_apple_zip.sh rejects the clean zip"
    indent < "$WORK/$P-clean.check"
  fi
  if [ "$P" = "macos" ]; then WHY="does not sign"; else WHY="sealed into its signature"; fi
  if "$CHECK" --platform "$P" "$WORK/$P-inline.zip" > "$WORK/$P-inline.check" 2>&1; then
    fail "$P: check_apple_zip.sh accepts the inline zip"
  elif grep -q "$WHY" "$WORK/$P-inline.check"; then
    pass "$P: check_apple_zip.sh rejects the inline zip ($WHY)"
  else
    fail "$P: check_apple_zip.sh rejects the inline zip, but not with \"$WHY\""
    indent < "$WORK/$P-inline.check"
  fi

  # The real setup script on each zip.
  for C in clean inline macosx; do
    R="$WORK/run-$P-$C"
    if ! run_setup "$P" "$C"; then
      fail "$P/$C: setup script failed"
      tail -15 "$R/log" | indent
      continue
    fi
    F="$R/pod/Frameworks"
    JUNK=$(find "$F" \( -name '._*' -o -name '__MACOSX' \) | wc -l | tr -d ' ')
    if [ "$JUNK" -eq 0 ]; then pass "$P/$C: setup installed no ._ files"
    else fail "$P/$C: setup installed $JUNK ._ or __MACOSX entries"; fi

    if [ "$P" = "macos" ]; then
      TREE="$F"
    else
      # The device slice of each .xcframework is what an iOS app embeds.
      TREE="$R/device"
      mkdir -p "$TREE"
      for FW in $FRAMEWORKS; do
        if [ -d "$F/$FW.xcframework/ios-arm64/$FW.framework" ]; then
          cp -R "$F/$FW.xcframework/ios-arm64/$FW.framework" "$TREE/"
        fi
      done
    fi
    if "$CHECK" --platform "$P" "$TREE" > "$R/check" 2>&1; then
      pass "$P/$C: installed frameworks pass check_apple_zip.sh"
    else
      fail "$P/$C: installed frameworks fail check_apple_zip.sh"
      indent < "$R/check"
    fi
  done
done

echo
if [ "$FAILURES" -eq 0 ]; then
  echo "PASS"
else
  echo "FAILED: $FAILURES check(s)"
  exit 1
fi
