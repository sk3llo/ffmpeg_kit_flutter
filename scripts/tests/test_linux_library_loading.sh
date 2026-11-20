#!/bin/bash
#
# Regression test: on Linux the plugin must load libffmpegkit.so from the app
# bundle Flutter builds, without LD_LIBRARY_PATH.
#
#   scripts/tests/test_linux_library_loading.sh
#
# Flutter copies the FFmpegKit libraries into the bundle's lib/, next to the
# plugin's library. The runner's $ORIGIN/lib is a DT_RUNPATH, which glibc
# applies only to the runner's own dependencies, not to a dlopen() made from
# the plugin; the plugin's own run path is the build machine's
# linux/flutter/ephemeral; and the bundled libraries have no run path. So a
# dlopen("libffmpegkit.so") from the plugin fails, and with it every FFmpegKit
# call.
#
# The test builds a bundle laid out the same way: stand-ins for libffmpegkit.so
# and the seven FFmpeg libraries (the same sonames, file names and links, each
# calling into the libraries it links), a runner linked with $ORIGIN/lib as its
# DT_RUNPATH, and a plugin library built from the plugin's real
# linux/ffmpeg_kit_library_loader.cc with a run path that doesn't exist here.
# Started without LD_LIBRARY_PATH, from any directory, the runner must reach
# libffmpegkit.so through the loader. With the libraries outside the bundle
# and LD_LIBRARY_PATH pointing at them, the loader must find them there.
#
# Self-checks keep the test honest: readelf must show the run paths above, and
# a plugin that calls dlopen("libffmpegkit.so") itself, as the plugin did
# before, must fail in the same bundle.
#
# Needs Linux with glibc, a C++ compiler (c++, or $CXX) and readelf. From
# macOS, run it in a Linux container, for example:
#   docker run --rm -v "$PWD":/src -w /src gcc:13 scripts/tests/test_linux_library_loading.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
CXX="${CXX:-c++}"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/test-linux-loading.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

FAILURES=0
pass() { echo "ok    $1"; }
fail() { echo "FAIL  $1"; FAILURES=$((FAILURES + 1)); }
indent() { sed 's/^/      /'; }

# <library>:<soname major>:<libraries it links>, each after the ones it links,
# as FFmpeg 8.1's libraries link each other.
LIBS="avutil:60: swresample:6:avutil swscale:9:avutil avcodec:62:avutil,swresample
avformat:62:avutil,avcodec avfilter:11:avutil,swscale,swresample,avcodec,avformat
avdevice:62:avutil,avcodec,avformat,avfilter
ffmpegkit:5:avutil,swresample,swscale,avcodec,avformat,avfilter,avdevice"

# Each stand-in returns 1 plus what the libraries it links return, so the
# runner's number shows that every link resolved.
declare -A VALUE
EXPECTED=0
for ENTRY in $LIBS; do
  IFS=: read -r NAME MAJOR DEPS <<<"$ENTRY"
  {
    for DEP in ${DEPS//,/ }; do echo "extern \"C\" int ${DEP}_stand_in(void);"; done
    printf 'extern "C" int %s_stand_in(void) { return 1' "$NAME"
    for DEP in ${DEPS//,/ }; do printf ' + %s_stand_in()' "$DEP"; done
    printf '; }\n'
  } >"$WORK/$NAME.cc"
  V=1
  for DEP in ${DEPS//,/ }; do V=$((V + ${VALUE[$DEP]})); done
  VALUE[$NAME]=$V
  EXPECTED=$V
done

# build_libs <dir>: lib<name>.so.<major>.0.0, soname lib<name>.so.<major>, and
# the two symlinks, as in the FFmpegKit Linux bundle; no run path.
build_libs() {
  local D="$1" ENTRY NAME MAJOR DEPS DEP LINK
  mkdir -p "$D"
  for ENTRY in $LIBS; do
    IFS=: read -r NAME MAJOR DEPS <<<"$ENTRY"
    LINK=()
    for DEP in ${DEPS//,/ }; do LINK+=("-l$DEP"); done
    "$CXX" -shared -fPIC -o "$D/lib$NAME.so.$MAJOR.0.0" "$WORK/$NAME.cc" \
      -Wl,-soname,"lib$NAME.so.$MAJOR" -L"$D" ${LINK[@]+"${LINK[@]}"}
    ln -sf "lib$NAME.so.$MAJOR.0.0" "$D/lib$NAME.so.$MAJOR"
    ln -sf "lib$NAME.so.$MAJOR" "$D/lib$NAME.so"
  done
}

cat >"$WORK/loader_plugin.cc" <<'CC'
#include <dlfcn.h>
#include <cstdio>
#include "ffmpeg_kit_library_loader.h"
extern "C" int plugin_run(void) {
  void* lib = ffmpeg_kit_load_library();
  if (lib == nullptr) { std::printf("%s\n", dlerror()); return -1; }
  auto fn = reinterpret_cast<int (*)(void)>(dlsym(lib, "ffmpegkit_stand_in"));
  return fn == nullptr ? -2 : fn();
}
CC
cat >"$WORK/bare_plugin.cc" <<'CC'
#include <dlfcn.h>
#include <cstdio>
extern "C" int plugin_run(void) {
  void* lib = dlopen("libffmpegkit.so", RTLD_NOW | RTLD_GLOBAL);
  if (lib == nullptr) { std::printf("%s\n", dlerror()); return -1; }
  auto fn = reinterpret_cast<int (*)(void)>(dlsym(lib, "ffmpegkit_stand_in"));
  return fn == nullptr ? -2 : fn();
}
CC
cat >"$WORK/runner.cc" <<'CC'
#include <cstdio>
extern "C" int plugin_run(void);
int main() { std::printf("%d\n", plugin_run()); return 0; }
CC

# bundle <dir> <plugin source...>: <dir>/runner and <dir>/lib/libtest_plugin.so,
# linked the way Flutter links an app's runner and its plugins.
bundle() {
  local B="$1"
  shift
  mkdir -p "$B/lib"
  "$CXX" -shared -fPIC -I"$ROOT/linux" -o "$B/lib/libtest_plugin.so" "$@" \
    -Wl,--enable-new-dtags -Wl,-rpath,/nonexistent/linux/flutter/ephemeral -ldl
  "$CXX" -o "$B/runner" "$WORK/runner.cc" -L"$B/lib" -ltest_plugin \
    -Wl,--enable-new-dtags -Wl,-rpath,'$ORIGIN/lib'
}

bundle "$WORK/fixed" "$WORK/loader_plugin.cc" "$ROOT/linux/ffmpeg_kit_library_loader.cc"
build_libs "$WORK/fixed/lib"
bundle "$WORK/bare" "$WORK/bare_plugin.cc"
build_libs "$WORK/bare/lib"
bundle "$WORK/outside" "$WORK/loader_plugin.cc" "$ROOT/linux/ffmpeg_kit_library_loader.cc"
build_libs "$WORK/elsewhere"

paths() { readelf -d "$1" | grep -E '\((RPATH|RUNPATH)\)' | sed -E 's/.*\((RPATH|RUNPATH)\).*\[(.*)\]/\1 \2/'; }

# Self-checks.
P="$(paths "$WORK/fixed/runner")"
if [ "$P" = 'RUNPATH $ORIGIN/lib' ]; then pass "the runner's run path is a DT_RUNPATH of \$ORIGIN/lib, as Flutter's is"
else fail "the runner's run path is '$P', not a DT_RUNPATH of \$ORIGIN/lib"; fi
P="$(paths "$WORK/fixed/lib/libtest_plugin.so")"
if [ "$P" = 'RUNPATH /nonexistent/linux/flutter/ephemeral' ]; then pass "the plugin's run path leads nowhere on this machine"
else fail "the plugin's run path is '$P'"; fi
N=0
for L in "$WORK"/fixed/lib/lib{avutil,swresample,swscale,avcodec,avformat,avfilter,avdevice,ffmpegkit}.so; do
  [ -z "$(paths "$L")" ] || N=$((N + 1))
done
if [ "$N" -eq 0 ]; then pass "the bundled libraries have no run path"
else fail "$N bundled libraries have a run path"; fi

OUT="$(cd / && env -u LD_LIBRARY_PATH "$WORK/bare/runner" 2>&1 || true)"
if echo "$OUT" | grep -q "libffmpegkit.so: cannot open shared object file"; then
  pass "dlopen(\"libffmpegkit.so\") from the plugin fails in this bundle"
else
  fail "dlopen(\"libffmpegkit.so\") from the plugin did not fail as the plugin did"
  echo "$OUT" | indent
fi

# The loader.
for DIR in / "$WORK/fixed" "$WORK/fixed/lib"; do
  OUT="$(cd "$DIR" && env -u LD_LIBRARY_PATH "$WORK/fixed/runner" 2>&1 || true)"
  if [ "$OUT" = "$EXPECTED" ]; then
    pass "the loader reaches libffmpegkit.so and every library it links, started from $DIR"
  else
    fail "the loader, started from $DIR: expected $EXPECTED, got:"
    echo "$OUT" | indent
  fi
done
OUT="$(cd / && LD_LIBRARY_PATH="$WORK/elsewhere" "$WORK/outside/runner" 2>&1 || true)"
if [ "$OUT" = "$EXPECTED" ]; then
  pass "with no bundled copy, the loader finds libffmpegkit.so through LD_LIBRARY_PATH"
else
  fail "with no bundled copy and LD_LIBRARY_PATH set: expected $EXPECTED, got:"
  echo "$OUT" | indent
fi

echo
if [ "$FAILURES" -eq 0 ]; then
  echo "PASS"
else
  echo "FAILED: $FAILURES check(s)"
  exit 1
fi
