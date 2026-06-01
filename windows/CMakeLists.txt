cmake_minimum_required(VERSION 3.14)

# Must match the pubspec package name so the generated public header lands at
# include/ffmpeg_kit_flutter_new/ where generated_plugin_registrant.cc expects it.
set(PROJECT_NAME "ffmpeg_kit_flutter_new")
project(${PROJECT_NAME} LANGUAGES CXX)

# Must match the Flutter plugin target name derived from the pubspec package
# name (ffmpeg_kit_flutter_new): generated_plugins.cmake links ${plugin}_plugin
# and bundles ${plugin}_bundled_libraries.
set(PLUGIN_NAME "ffmpeg_kit_flutter_new_plugin")

add_library(${PLUGIN_NAME} SHARED
  "ffmpeg_kit_flutter_plugin.cpp"
  "ffmpeg_kit_flutter_plugin_c_api.cpp"
)

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_STANDARD 17
  CXX_VISIBILITY_PRESET hidden)

target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

set(PUBLIC_HEADER_DIR "${CMAKE_CURRENT_BINARY_DIR}/include/${PROJECT_NAME}")
file(MAKE_DIRECTORY "${PUBLIC_HEADER_DIR}")
file(WRITE "${PUBLIC_HEADER_DIR}/f_fmpeg_kit_flutter_plugin.h" [=[
#ifndef FLUTTER_PLUGIN_FFMPEG_KIT_FLUTTER_PLUGIN_C_API_H_
#define FLUTTER_PLUGIN_FFMPEG_KIT_FLUTTER_PLUGIN_C_API_H_

#include <flutter_plugin_registrar.h>

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FLUTTER_PLUGIN_EXPORT __declspec(dllimport)
#endif

#if defined(__cplusplus)
extern "C" {
#endif

FLUTTER_PLUGIN_EXPORT void FFmpegKitFlutterPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

#if defined(__cplusplus)
}
#endif

#endif  // FLUTTER_PLUGIN_FFMPEG_KIT_FLUTTER_PLUGIN_C_API_H_
]=])

target_include_directories(${PLUGIN_NAME} PRIVATE
  "${CMAKE_CURRENT_BINARY_DIR}")
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_BINARY_DIR}/include")

target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

if(CMAKE_SYSTEM_PROCESSOR STREQUAL "AMD64" OR CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64")
  set(FFMPEGKIT_ARCH "x86_64")
elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "X86" OR CMAKE_SYSTEM_PROCESSOR STREQUAL "i686")
  set(FFMPEGKIT_ARCH "i686")
elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "ARM64" OR CMAKE_SYSTEM_PROCESSOR STREQUAL "aarch64")
  set(FFMPEGKIT_ARCH "aarch64")
else()
  set(FFMPEGKIT_ARCH "x86_64")
endif()

set(FFMPEGKIT_PREBUILT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ffmpeg-kit")
message(STATUS "FFmpegKit prebuilt dir: ${FFMPEGKIT_PREBUILT_DIR} (arch: ${FFMPEGKIT_ARCH})")

# FFmpegKit package variant to consume.
#
# Default is "full-gpl" so the GPL codec set (x264, x265, xvid, vid.stab, ...) is
# available. NOTE the distinction:
#   * The PUBLISHED Windows "full-gpl" release is a reduced custom build
#     (x264/aom/dav1d/openh264/kvazaar/ilbc/zimg/openssl/srt + gpl). It provides
#     libx264 and HTTPS, but FFmpegKitConfig.getPackageName() still reports "min"
#     because it lacks the full 27-library signature.
#   * A CANONICAL full-gpl build (reports "full-gpl", full library set, and
#     includes the native threading/leak/locking fixes) is produced by
#     ffmpeg-kit/build-windows-full-gpl.sh — consume it by setting FFMPEGKIT_LOCAL_DIR.
set(FFMPEGKIT_PACKAGE "full-gpl" CACHE STRING "FFmpegKit variant: full-gpl, full, min-gpl, min, https, ...")
set(FFMPEGKIT_VERSION "8.0.0" CACHE STRING "FFmpegKit release version")
set(FFMPEGKIT_LOCAL_DIR "" CACHE PATH "Path to a locally-built bundle (dir containing bin/ [+ include/]) to use instead of downloading")

# Allow pointing at a local bundle via the environment too, so it can be set
# without forwarding -D through `flutter run/build` (which inherits the env):
#   set FFMPEGKIT_LOCAL_DIR=C:/.../ffmpeg-kit/prebuilt/bundle-windows-x86_64/ffmpeg-kit
if(NOT FFMPEGKIT_LOCAL_DIR AND DEFINED ENV{FFMPEGKIT_LOCAL_DIR})
  set(FFMPEGKIT_LOCAL_DIR "$ENV{FFMPEGKIT_LOCAL_DIR}")
endif()

# The Windows native libraries are published under a windows-specific GitHub
# release tag (e.g. 8.0.0-full-gpl-windows) so they don't collide with other
# platforms' artifacts.
set(FFMPEGKIT_RELEASE_TAG "${FFMPEGKIT_VERSION}-${FFMPEGKIT_PACKAGE}-windows")
set(FFMPEGKIT_ZIP_NAME "ffmpeg-kit-windows-${FFMPEGKIT_ARCH}-${FFMPEGKIT_PACKAGE}-${FFMPEGKIT_VERSION}.zip")
set(FFMPEGKIT_DOWNLOAD_URL "https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/${FFMPEGKIT_RELEASE_TAG}/${FFMPEGKIT_ZIP_NAME}")
set(FFMPEGKIT_ZIP_PATH "${FFMPEGKIT_PREBUILT_DIR}/${FFMPEGKIT_ZIP_NAME}")

# Marker recording which variant is currently installed, so changing
# FFMPEGKIT_PACKAGE / FFMPEGKIT_LOCAL_DIR triggers a clean re-fetch.
set(FFMPEGKIT_MARKER "${FFMPEGKIT_PREBUILT_DIR}/bin/.ffmpegkit_variant")
if(FFMPEGKIT_LOCAL_DIR)
  set(FFMPEGKIT_WANT "local:${FFMPEGKIT_LOCAL_DIR}")
else()
  set(FFMPEGKIT_WANT "${FFMPEGKIT_RELEASE_TAG}")
endif()
set(FFMPEGKIT_HAVE "")
if(EXISTS "${FFMPEGKIT_MARKER}")
  file(READ "${FFMPEGKIT_MARKER}" FFMPEGKIT_HAVE)
  string(STRIP "${FFMPEGKIT_HAVE}" FFMPEGKIT_HAVE)
endif()

if(NOT "${FFMPEGKIT_HAVE}" STREQUAL "${FFMPEGKIT_WANT}")
  file(REMOVE_RECURSE "${FFMPEGKIT_PREBUILT_DIR}/bin")
  file(MAKE_DIRECTORY "${FFMPEGKIT_PREBUILT_DIR}")
  if(FFMPEGKIT_LOCAL_DIR)
    if(NOT EXISTS "${FFMPEGKIT_LOCAL_DIR}/bin/libffmpegkit.dll")
      message(FATAL_ERROR "FFMPEGKIT_LOCAL_DIR=${FFMPEGKIT_LOCAL_DIR} has no bin/libffmpegkit.dll")
    endif()
    message(STATUS "FFmpegKit: installing local bundle from ${FFMPEGKIT_LOCAL_DIR}")
    file(COPY "${FFMPEGKIT_LOCAL_DIR}/bin" DESTINATION "${FFMPEGKIT_PREBUILT_DIR}")
    if(EXISTS "${FFMPEGKIT_LOCAL_DIR}/include")
      file(REMOVE_RECURSE "${FFMPEGKIT_PREBUILT_DIR}/include")
      file(COPY "${FFMPEGKIT_LOCAL_DIR}/include" DESTINATION "${FFMPEGKIT_PREBUILT_DIR}")
    endif()
  else()
    message(STATUS "FFmpegKit: downloading ${FFMPEGKIT_PACKAGE} from ${FFMPEGKIT_DOWNLOAD_URL}")
    file(DOWNLOAD
      "${FFMPEGKIT_DOWNLOAD_URL}"
      "${FFMPEGKIT_ZIP_PATH}"
      SHOW_PROGRESS
      STATUS FFMPEGKIT_DOWNLOAD_STATUS
    )
    list(GET FFMPEGKIT_DOWNLOAD_STATUS 0 FFMPEGKIT_DOWNLOAD_CODE)
    list(GET FFMPEGKIT_DOWNLOAD_STATUS 1 FFMPEGKIT_DOWNLOAD_MSG)
    if(NOT FFMPEGKIT_DOWNLOAD_CODE EQUAL 0)
      file(REMOVE "${FFMPEGKIT_ZIP_PATH}")
      message(FATAL_ERROR "Failed to download FFmpegKit (${FFMPEGKIT_PACKAGE}): ${FFMPEGKIT_DOWNLOAD_MSG}")
    endif()
    execute_process(
      COMMAND ${CMAKE_COMMAND} -E tar xf "${FFMPEGKIT_ZIP_PATH}"
      WORKING_DIRECTORY "${FFMPEGKIT_PREBUILT_DIR}"
      RESULT_VARIABLE FFMPEGKIT_UNZIP_RESULT
    )
    file(REMOVE "${FFMPEGKIT_ZIP_PATH}")
    if(NOT FFMPEGKIT_UNZIP_RESULT EQUAL 0)
      message(FATAL_ERROR "Failed to extract FFmpegKit archive")
    endif()
  endif()
  file(WRITE "${FFMPEGKIT_MARKER}" "${FFMPEGKIT_WANT}\n")
  message(STATUS "FFmpegKit ${FFMPEGKIT_WANT} ready")
endif()

# Bundle every DLL shipped in the prebuilt bin/. The full-gpl build links the
# external codecs statically into the av* DLLs, but globbing also picks up any
# extra MinGW runtime DLLs and is robust to FFmpeg soname bumps (avcodec-61 ->
# 62, etc.) without editing this list.
file(GLOB FFMPEGKIT_DLLS "${FFMPEGKIT_PREBUILT_DIR}/bin/*.dll")
if(NOT FFMPEGKIT_DLLS)
  message(FATAL_ERROR "FFmpegKit: no DLLs found in ${FFMPEGKIT_PREBUILT_DIR}/bin")
endif()

# MinGW-compiled DLLs ship with HIGH_ENTROPY_VA + DYNAMIC_BASE enabled and
# many share the same preferred ImageBase (0x180000000). When ASLR is on, or
# when overlapping DLLs force the loader to rebase, modules land far apart
# in 64-bit address space and MinGW's 32-bit pseudo-relocations overflow.
#
# Fix: clear ASLR flags and rebase every DLL into a compact, non-overlapping
# range starting at 0x10000000 so pseudo-relocs stay within +-2GB.
get_filename_component(MSVC_TOOLS_DIR "${CMAKE_CXX_COMPILER}" DIRECTORY)
find_program(EDITBIN_EXECUTABLE editbin HINTS "${MSVC_TOOLS_DIR}" REQUIRED)

add_custom_command(
    OUTPUT "${FFMPEGKIT_PREBUILT_DIR}/bin/.high_entropy_patched"
    COMMAND "${EDITBIN_EXECUTABLE}" /NOLOGO /HIGHENTROPYVA:NO /DYNAMICBASE:NO /REBASE:BASE=0x10000000 ${FFMPEGKIT_DLLS}
    COMMAND ${CMAKE_COMMAND} -E touch "${FFMPEGKIT_PREBUILT_DIR}/bin/.high_entropy_patched"
    DEPENDS ${FFMPEGKIT_DLLS}
    COMMENT "Patching MinGW FFmpegKit DLLs (ASLR off + rebase)"
)
add_custom_target(patch_ffmpegkit_dlls DEPENDS "${FFMPEGKIT_PREBUILT_DIR}/bin/.high_entropy_patched")
add_dependencies(${PLUGIN_NAME} patch_ffmpegkit_dlls)

set(ffmpeg_kit_flutter_new_bundled_libraries
  ${FFMPEGKIT_DLLS}
  PARENT_SCOPE
)
