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
# It also covers the optional download check (issue #174). With
# FFMPEG_KIT_{MACOS,IOS}_SHA256 set, setup must install the zip only when its
# SHA-256 matches, and leave no ./Frameworks otherwise. Without the variable
# it must not check a digest at all.
#
# And the dSYMs that zips carry from 8.1.3 on: each tree has a
# <name>.framework.dSYM beside each framework, and setup must install every
# one where CocoaPods looks for it, with the binary's UUIDs (iOS: in
# <name>.dSYMs/ beside the .xcframework, covering both slices; macOS: beside
# the framework). A zip without dSYMs, like 8.1.2's, must still install.
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

# with_dsym <binary> <dSYM>: the dSYM a release build makes, then the strip.
# dsymutil reads the DWARF from the object files the binary was linked from.
with_dsym() {
  xcrun dsymutil "$1" -o "$2" && xcrun strip -x "$1"
}

make_macos_tree() {  # <out>
  local OUT="$1" FW D A
  for FW in $FRAMEWORKS; do
    D="$OUT/$FW.framework"
    mkdir -p "$D/Versions/A/Headers" "$D/Versions/A/Resources"
    printf 'int %s_test(void) { return 0; }\n' "$FW" > "$WORK/$FW.c"
    for A in arm64 x86_64; do
      xcrun --sdk macosx clang -arch $A -mmacosx-version-min=10.15 -g -c \
        -o "$WORK/$FW-mac-$A.o" "$WORK/$FW.c"
      xcrun --sdk macosx clang -arch $A -mmacosx-version-min=10.15 -dynamiclib \
        -install_name "@rpath/$FW.framework/Versions/A/$FW" -o "$WORK/$FW-mac-$A" "$WORK/$FW-mac-$A.o"
    done
    lipo -create "$WORK/$FW-mac-arm64" "$WORK/$FW-mac-x86_64" -output "$D/Versions/A/$FW"
    with_dsym "$D/Versions/A/$FW" "$OUT/$FW.framework.dSYM"
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
    xcrun --sdk iphoneos clang -arch arm64 -miphoneos-version-min=14.0 -g -c \
      -o "$WORK/$FW-device.o" "$WORK/$FW.c"
    xcrun --sdk iphoneos clang -arch arm64 -miphoneos-version-min=14.0 -dynamiclib \
      -install_name "@rpath/$FW.framework/$FW" -o "$WORK/$FW-device" "$WORK/$FW-device.o"
    xcrun --sdk iphonesimulator clang -arch x86_64 -mios-simulator-version-min=14.0 -g -c \
      -o "$WORK/$FW-sim.o" "$WORK/$FW.c"
    xcrun --sdk iphonesimulator clang -arch x86_64 -mios-simulator-version-min=14.0 -dynamiclib \
      -install_name "@rpath/$FW.framework/$FW" -o "$WORK/$FW-sim" "$WORK/$FW-sim.o"
    lipo -create "$WORK/$FW-device" "$WORK/$FW-sim" -output "$D/$FW"
    with_dsym "$D/$FW" "$OUT/$FW.framework.dSYM"
    printf 'int %s_test(void);\n' "$FW" > "$D/Headers/$FW.h"
    plist "$D/Info.plist" "$FW" iPhoneOS
  done
}

count_entries() {  # <zip> <regex>
  unzip -Z1 "$1" | grep -cE "$2" || true
}

uuids() {  # <binary or dSYM>: "UUID (arch)" per architecture
  dwarfdump --uuid "$1" 2>/dev/null | awk '{print $2, $3}' | sort
}

# dsym_problems <platform> <Frameworks dir>: names each framework whose
# installed dSYM is missing or doesn't have its binary's UUIDs. On iOS the one
# dSYM must match the simulator slice (x86_64 and the retagged arm64) and hold
# the device slice's arm64 UUID too.
dsym_problems() {
  local P="$1" F="$2" FW SYM DEV
  for FW in $FRAMEWORKS; do
    if [ "$P" = "macos" ]; then
      SYM="$F/$FW.framework.dSYM"
      { [ -d "$SYM" ] && [ "$(uuids "$F/$FW.framework/Versions/A/$FW")" = "$(uuids "$SYM")" ]; } || echo "$FW"
    else
      SYM="$F/$FW.dSYMs/$FW.framework.dSYM"
      DEV="$(uuids "$F/$FW.xcframework/ios-arm64/$FW.framework/$FW")"
      { [ -d "$SYM" ] && [ -n "$DEV" ] &&
        [ "$(uuids "$F/$FW.xcframework/ios-arm64_x86_64-simulator/$FW.framework/$FW")" = "$(uuids "$SYM")" ] &&
        uuids "$SYM" | grep -qxF "$DEV"; } || echo "$FW"
    fi
  done
}

# run_setup <platform> <case> [sha256 [run]] installs the <case> zip into
# $WORK/run-<platform>-<run>/pod; <run> defaults to <case>. SETUP_PATH, when
# set, is the PATH the setup script runs with.
run_setup() {
  local P="$1" C="$2" SHA="${3:-}" R="$WORK/run-$1-${4:-$2}"
  rm -rf "$R"
  mkdir -p "$R/pod"
  if [ "$P" = "macos" ]; then
    (cd "$R/pod" && PATH="${SETUP_PATH:-$PATH}" FFMPEG_KIT_MACOS_URL="file://$WORK/$P-$C.zip" FFMPEG_KIT_MACOS_SHA256="$SHA" /bin/bash "$SCRIPTS/setup_macos.sh") > "$R/log" 2>&1
  else
    (cd "$R/pod" && PATH="${SETUP_PATH:-$PATH}" FFMPEG_KIT_IOS_URL="file://$WORK/$P-$C.zip" FFMPEG_KIT_IOS_SHA256="$SHA" /bin/bash "$SCRIPTS/setup_ios.sh") > "$R/log" 2>&1
  fi
}

verifies() {  # <platform> <run> <sha256> <label>: setup installs the clean zip and reports the check
  local P="$1" R="$WORK/run-$1-$2"
  if run_setup "$P" clean "$3" "$2" && grep -q "SHA-256 verified" "$R/log"; then
    pass "$P: $4"
  else
    fail "$P: $4"
    tail -15 "$R/log" | indent
  fi
}

refuses() {  # <platform> <run> <sha256> <error> <label>: setup fails with <error> and installs nothing
  local P="$1" R="$WORK/run-$1-$2"
  if run_setup "$P" clean "$3" "$2"; then
    fail "$P: $5 (setup succeeded)"
  elif ! grep -q "$4" "$R/log"; then
    fail "$P: $5 (it failed for another reason)"
    tail -15 "$R/log" | indent
  elif [ -e "$R/pod/Frameworks" ]; then
    fail "$P: $5 (./Frameworks was left behind)"
  else
    pass "$P: $5"
  fi
}

# PATH prefixes that hide the hashing tools one by one, so the setup scripts
# fall back from shasum to sha256sum to openssl, and then run out.
for N in 1 2 3; do mkdir -p "$WORK/hide$N"; done
for D in hide1/shasum hide2/shasum hide2/sha256sum hide3/shasum hide3/sha256sum hide3/openssl; do
  printf '#!/bin/sh\nexit 127\n' > "$WORK/$D"
  chmod +x "$WORK/$D"
done

for P in macos ios; do
  T="$WORK/tree-$P"
  mkdir -p "$T"
  if [ "$P" = "macos" ]; then make_macos_tree "$T"; else make_ios_tree "$T"; fi
  # A zip without dSYMs, as 8.1.2 and earlier shipped.
  mkdir -p "$WORK/tree-$P-nodsym" && cp -R "$T"/*.framework "$WORK/tree-$P-nodsym/"
  ditto -c -k --norsrc --noextattr --noacl "$WORK/tree-$P-nodsym" "$WORK/$P-nodsym.zip"
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
    N=$(dsym_problems "$P" "$F" | paste -sd, - | sed 's/,/, /g')
    if [ -z "$N" ]; then pass "$P/$C: every framework got its dSYM, with the binary's UUIDs"
    else fail "$P/$C: dSYM missing or with other UUIDs: $N"; fi
  done

  # A zip without dSYMs installs, with none.
  R="$WORK/run-$P-nodsym"
  if ! run_setup "$P" nodsym; then
    fail "$P/nodsym: setup script failed"
    tail -15 "$R/log" | indent
  elif [ -n "$(find "$R/pod/Frameworks" -name '*.dSYM*')" ]; then
    fail "$P/nodsym: setup installed dSYMs: $(find "$R/pod/Frameworks" -name '*.dSYM*' | head -2 | tr '\n' ' ')"
  else
    pass "$P/nodsym: setup installs the frameworks, with no dSYMs"
  fi

  # The optional SHA-256 check (#174), on the clean zip.
  SHA="$(shasum -a 256 "$WORK/$P-clean.zip" | awk '{print $1}')"
  VAR="FFMPEG_KIT_$(printf '%s' "$P" | tr '[:lower:]' '[:upper:]')_SHA256"
  if grep -q "SHA-256" "$WORK/run-$P-clean/log"; then
    fail "$P: setup checked a SHA-256 without $VAR"
  else
    pass "$P: setup checks no SHA-256 without $VAR"
  fi
  verifies "$P" sha-ok "$SHA" "setup accepts the zip's SHA-256 in $VAR"
  verifies "$P" sha-prefixed "sha256:$(printf '%s' "$SHA" | tr '[:lower:]' '[:upper:]')" \
    "setup accepts it in upper case with a sha256: prefix"
  refuses "$P" sha-wrong "$(printf '%064d' 0)" "does not match $VAR" \
    "setup refuses a zip with another SHA-256"
  refuses "$P" sha-malformed "abc123" "is not a SHA-256 digest" "setup refuses a malformed $VAR"
  if grep -q "Downloading" "$WORK/run-$P-sha-malformed/log"; then
    fail "$P: setup downloaded the zip before refusing a malformed $VAR"
  else
    pass "$P: setup refuses a malformed $VAR before downloading"
  fi
  SETUP_PATH="$WORK/hide1:$PATH" verifies "$P" sha-no-shasum "$SHA" "setup verifies without shasum"
  SETUP_PATH="$WORK/hide2:$PATH" verifies "$P" sha-openssl "$SHA" "setup verifies with openssl alone"
  SETUP_PATH="$WORK/hide3:$PATH" refuses "$P" sha-no-tool "$SHA" "Could not compute" \
    "setup refuses the zip when no tool can hash it"
done

echo
if [ "$FAILURES" -eq 0 ]; then
  echo "PASS"
else
  echo "FAILED: $FAILURES check(s)"
  exit 1
fi
