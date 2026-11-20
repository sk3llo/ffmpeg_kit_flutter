#!/bin/bash
#
# Regression test: the Windows and Linux builds must use the FFmpegKit release
# the installed plugin names, also in a build folder that an older plugin
# version, or another of the packages, configured before.
#
#   scripts/tests/test_desktop_cmake_release.sh
#
# windows/CMakeLists.txt and linux/CMakeLists.txt pick the release with
# set(FFMPEGKIT_PACKAGE ...) and set(FFMPEGKIT_VERSION ...), and build the
# release tag from them. Flutter keeps an app's CMake cache from one build to
# the next, so as cache entries they would keep their first values after the
# plugin changed, and the app would go on downloading the old release until
# `flutter clean`.
#
# For each file the test takes those three lines, configures a project with the
# values an older plugin had (version 0.0.1, package "old"), then configures
# the same build folder with the lines as they are now, as the first build
# after an upgrade does. The release tag must then be the current one.
#
# Self-check: with the lines turned back into cache entries the same steps must
# keep the old tag, or the test could not tell a fixed file from a broken one.
#
# Needs CMake 3.13 or later.
#
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
CMAKE="${CMAKE:-cmake}"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/test-desktop-cmake.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

FAILURES=0
pass() { echo "ok    $1"; }
fail() { echo "FAIL  $1"; FAILURES=$((FAILURES + 1)); }

# tag <source dir> <build dir>: configures, prints the release tag.
tag() {
  "$CMAKE" -S "$1" -B "$2" >"$2.log" 2>&1 || { sed 's/^/      /' "$2.log" >&2; return 1; }
  sed -n 's/^-- RELEASE_TAG=//p' "$2.log"
}

# upgrade <name> <lines before> <lines after>: the release tag after one build
# folder is configured with the first lines and then with the second.
upgrade() {
  local P="$WORK/$1" FIRST
  mkdir -p "$P/src"
  cat >"$P/src/CMakeLists.txt" <<'CMAKE'
cmake_minimum_required(VERSION 3.13)
project(release NONE)
include("${CMAKE_CURRENT_SOURCE_DIR}/release.cmake")
message(STATUS "RELEASE_TAG=${FFMPEGKIT_RELEASE_TAG}")
CMAKE
  printf '%s\n' "$2" >"$P/src/release.cmake"
  FIRST="$(tag "$P/src" "$P/build")" || return 1
  [ "$FIRST" = "0.0.1-old" ] || { echo "the first configure gave '$FIRST'" >&2; return 1; }
  printf '%s\n' "$3" >"$P/src/release.cmake"
  tag "$P/src" "$P/build"
}

for PLAT in windows linux; do
  LINES="$(grep -E '^set\(FFMPEGKIT_(PACKAGE|VERSION|RELEASE_TAG) ' "$ROOT/$PLAT/CMakeLists.txt" || true)"
  N=$(printf '%s\n' "$LINES" | grep -c . || true)
  if [ "$N" -ne 3 ]; then
    fail "$PLAT: expected one set() each for FFMPEGKIT_PACKAGE, FFMPEGKIT_VERSION and FFMPEGKIT_RELEASE_TAG, found $N"
    continue
  fi
  PACKAGE=$(printf '%s\n' "$LINES" | sed -n 's/^set(FFMPEGKIT_PACKAGE "\([^"]*\)".*/\1/p')
  VERSION=$(printf '%s\n' "$LINES" | sed -n 's/^set(FFMPEGKIT_VERSION "\([^"]*\)".*/\1/p')
  OLD=$(printf '%s\n' "$LINES" | sed -E \
    -e 's/^set\(FFMPEGKIT_PACKAGE "[^"]*"/set(FFMPEGKIT_PACKAGE "old"/' \
    -e 's/^set\(FFMPEGKIT_VERSION "[^"]*"/set(FFMPEGKIT_VERSION "0.0.1"/')

  if GOT="$(upgrade "$PLAT" "$OLD" "$LINES")"; then
    if [ "$GOT" = "$VERSION-$PACKAGE" ]; then
      pass "$PLAT: after an upgrade the build folder uses $VERSION-$PACKAGE"
    else
      fail "$PLAT: after an upgrade the build folder still uses '$GOT', not $VERSION-$PACKAGE"
    fi
  else
    fail "$PLAT: configuring failed"
  fi

  cached() { sed -E 's/^(set\(FFMPEGKIT_(PACKAGE|VERSION) "[^"]*")\)$/\1 CACHE STRING "")/'; }
  if GOT="$(upgrade "$PLAT-cached" "$(printf '%s\n' "$OLD" | cached)" "$(printf '%s\n' "$LINES" | cached)")" &&
    [ "$GOT" = "0.0.1-old" ]; then
    pass "$PLAT: as cache entries the same lines keep 0.0.1-old"
  else
    fail "$PLAT: as cache entries the lines gave '${GOT:-}', so this test can't see the problem"
  fi
done

echo
if [ "$FAILURES" -eq 0 ]; then
  echo "PASS"
else
  echo "FAILED: $FAILURES check(s)"
  exit 1
fi
