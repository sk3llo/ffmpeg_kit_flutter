#!/bin/bash
#
# Release gate for the prebuilt Apple framework zips that setup_ios.sh and
# setup_macos.sh download (ffmpeg-kit-{ios,macos}-<variant>-<version>.zip).
# Run it on every zip before uploading it to a release:
#
#   scripts/check_apple_zip.sh ffmpeg-kit-ios-min-8.1.2.zip ffmpeg-kit-macos-min-8.1.2.zip
#   scripts/check_apple_zip.sh --platform macos path/to/dir-with-the-frameworks
#
# The platform comes from the zip name (-ios- / -macos-) unless --platform is
# given. A directory argument is checked as an already extracted tree. Exits
# non-zero if any argument fails.
#
# Why (issue #170): the 8.1.1 and 8.1.2 zips were made with plain `ditto -c -k`,
# which stores every file's extended attributes as a `._<name>` AppleDouble
# file next to it. unzip writes those out as real files, and codesign refuses
# to sign a macOS framework with extra files in its root ("unsealed contents
# present in the root directory of an embedded framework"), so every CocoaPods
# macOS build failed at CodeSign. This gate checks that:
#   1. there are no `._*` or `__MACOSX` entries;
#   2. all 8 frameworks are present with their Info.plist and binary;
#   3. macOS: each framework root holds only Versions/ and symlinks into
#      Versions/Current, which points at A;
#   4. the frameworks sign the way CocoaPods and Xcode sign them: each one
#      ad-hoc after the same copy as CocoaPods' embed phase, then on macOS an
#      app embedding them, verified with `codesign --verify --deep --strict`.
#      On iOS it also checks that no `._` file ends up sealed into a
#      framework's signature.
#
# Needs the Xcode command line tools (codesign, clang, unzip, rsync).
#
set -euo pipefail

FRAMEWORKS="ffmpegkit libavcodec libavdevice libavfilter libavformat libavutil libswresample libswscale"

usage() {
  echo "usage: $0 [--platform ios|macos] <zip|dir>..." >&2
  exit 2
}

PLATFORM=""
TARGETS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --platform)
      [ $# -ge 2 ] || usage
      PLATFORM="$2"
      shift 2
      ;;
    -h|--help) usage ;;
    *)
      TARGETS+=("$1")
      shift
      ;;
  esac
done
[ ${#TARGETS[@]} -gt 0 ] || usage
case "$PLATFORM" in ""|ios|macos) ;; *) usage ;; esac

WORK="$(mktemp -d "${TMPDIR:-/tmp}/check-apple-zip.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

# Main executable for the throwaway macOS app used by the signing check.
printf 'int main(void) { return 0; }\n' | xcrun clang -x c - -o "$WORK/host"

PROBLEMS=()
problem() { PROBLEMS+=("$1"); }

# codesign messages carry the throwaway paths; keep only the part that matters.
tidy_one() { sed -E 's#^.*/sign/[^:]*: ##'; }
tidy_all() { sed -E 's#[^ ]*/sign/##g' | tr '\n' ' ' | sed 's/ *$//'; }

# Copy a framework the way CocoaPods' "[CP] Embed Pods Frameworks" phase does.
embed_copy() {
  rsync -a --links --filter "- CVS/" --filter "- .svn/" --filter "- .git/" \
    --filter "- .hg/" --filter "- Headers" --filter "- PrivateHeaders" \
    --filter "- Modules" "$1" "$2/"
}

check_shape() {
  local TREE="$1" PLAT="$2" FW D E N
  for FW in $FRAMEWORKS; do
    D="$TREE/${FW}.framework"
    if [ ! -d "$D" ]; then
      problem "missing ${FW}.framework"
      continue
    fi
    if [ "$PLAT" = "macos" ]; then
      [ -f "$D/Versions/A/Resources/Info.plist" ] || problem "${FW}.framework: no Versions/A/Resources/Info.plist"
      [ -f "$D/Versions/A/${FW}" ] || problem "${FW}.framework: no Versions/A/${FW} binary"
      [ "$(readlink "$D/Versions/Current" 2>/dev/null || true)" = "A" ] || \
        problem "${FW}.framework: Versions/Current is not a symlink to A"
      for E in "$D"/* "$D"/.[!.]*; do
        [ -e "$E" ] || [ -L "$E" ] || continue
        N="$(basename "$E")"
        case "$N" in ._*) continue ;; esac  # counted by the AppleDouble check
        if [ "$N" = "Versions" ]; then
          { [ -d "$E" ] && [ ! -L "$E" ]; } || problem "${FW}.framework: Versions is not a directory"
        elif [ -L "$E" ]; then
          case "$(readlink "$E")" in
            Versions/Current/*) ;;
            *) problem "${FW}.framework/$N: symlink does not point into Versions/Current" ;;
          esac
        else
          problem "${FW}.framework/$N: a real file or directory in the framework root"
        fi
      done
    else
      [ -f "$D/Info.plist" ] || problem "${FW}.framework: no Info.plist"
      [ -f "$D/${FW}" ] || problem "${FW}.framework: no ${FW} binary"
    fi
  done
}

check_signing_macos() {
  local TREE="$1" APP="$WORK/sign/T.app" FW OUT
  rm -rf "$WORK/sign"
  mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Frameworks"
  cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>T</string>
  <key>CFBundleIdentifier</key><string>com.example.check-apple-zip</string>
  <key>CFBundlePackageType</key><string>APPL</string>
</dict></plist>
PLIST
  cp "$WORK/host" "$APP/Contents/MacOS/T"
  for FW in $FRAMEWORKS; do
    [ -d "$TREE/${FW}.framework" ] || continue
    embed_copy "$TREE/${FW}.framework" "$APP/Contents/Frameworks"
    if ! OUT=$(codesign --force --sign - --preserve-metadata=identifier,entitlements \
        "$APP/Contents/Frameworks/${FW}.framework" 2>&1); then
      problem "${FW}.framework does not sign: $(echo "$OUT" | grep -v 'replacing existing signature' | tail -1 | tidy_one)"
    fi
  done
  if ! OUT=$(codesign --force --sign - "$APP" 2>&1); then
    problem "an app embedding the frameworks does not sign: $(echo "$OUT" | grep -v 'replacing existing signature' | tidy_all)"
  elif ! OUT=$(codesign --verify --deep --strict "$APP" 2>&1); then
    problem "codesign --verify --deep --strict fails: $(echo "$OUT" | tidy_all)"
  fi
}

check_signing_ios() {
  local TREE="$1" DIR="$WORK/sign/P.app/Frameworks" FW OUT N
  rm -rf "$WORK/sign"
  mkdir -p "$DIR"
  for FW in $FRAMEWORKS; do
    [ -d "$TREE/${FW}.framework" ] || continue
    embed_copy "$TREE/${FW}.framework" "$DIR"
    if ! OUT=$(codesign --force --sign - "$DIR/${FW}.framework" 2>&1); then
      problem "${FW}.framework does not sign: $(echo "$OUT" | grep -v 'replacing existing signature' | tail -1 | tidy_one)"
      continue
    fi
    if ! OUT=$(codesign --verify --strict "$DIR/${FW}.framework" 2>&1); then
      problem "${FW}.framework fails codesign --verify --strict: $(echo "$OUT" | tidy_all)"
    fi
    N=$(grep -cE '<key>([^<]*/)?\._[^<]*</key>' "$DIR/${FW}.framework/_CodeSignature/CodeResources" || true)
    [ "$N" -eq 0 ] || problem "${FW}.framework: $N AppleDouble (._*) files sealed into its signature"
  done
}

STATUS=0
FAILED=0
for T in "${TARGETS[@]}"; do
  PROBLEMS=()
  P="$PLATFORM"
  if [ -z "$P" ]; then
    case "$(basename "$T")" in
      *-ios-*) P="ios" ;;
      *-macos-*) P="macos" ;;
      *)
        echo "FAIL $T: cannot tell ios from macos by the name, pass --platform"
        STATUS=1
        FAILED=$((FAILED + 1))
        continue
        ;;
    esac
  fi

  if [ -d "$T" ]; then
    TREE="$T"
    JUNK=$(find "$TREE" \( -name '._*' -o -name '__MACOSX' \) | wc -l | tr -d ' ')
    EXAMPLE=$(find "$TREE" \( -name '._*' -o -name '__MACOSX' \) | head -1 | sed "s#^$TREE/##")
    WHAT="tree"
  elif [ -f "$T" ] && unzip -tq "$T" >/dev/null 2>&1; then
    JUNK=$(unzip -Z1 "$T" | grep -cE '(^|/)(\._|__MACOSX(/|$))' || true)
    EXAMPLE=$(unzip -Z1 "$T" | grep -E '(^|/)(\._|__MACOSX(/|$))' | head -1 || true)
    TREE="$WORK/tree"
    rm -rf "$TREE"
    mkdir -p "$TREE"
    unzip -q "$T" -d "$TREE"
    WHAT="zip, $(unzip -Z1 "$T" | wc -l | tr -d ' ') entries"
  else
    echo "FAIL $T: not a directory or a readable zip"
    STATUS=1
    FAILED=$((FAILED + 1))
    continue
  fi

  [ "$JUNK" -eq 0 ] || problem "$JUNK AppleDouble (._*) or __MACOSX entries, e.g. $EXAMPLE"
  check_shape "$TREE" "$P"
  if [ "$P" = "macos" ]; then
    check_signing_macos "$TREE"
  else
    check_signing_ios "$TREE"
  fi

  if [ ${#PROBLEMS[@]} -eq 0 ]; then
    echo "PASS $T ($P $WHAT)"
  else
    STATUS=1
    FAILED=$((FAILED + 1))
    echo "FAIL $T ($P $WHAT)"
    for M in "${PROBLEMS[@]}"; do
      echo "  - $M"
    done
  fi
done
echo "checked ${#TARGETS[@]}, failed $FAILED"
exit $STATUS
