cmake_minimum_required(VERSION 3.10)
project(hidapi_compat C)

# Build a tiny shared library that exports PLATFORM_hid_write as a no-op and
# promotes itself to RTLD_GLOBAL via JNI_OnLoad. This satisfies the dynamic
# linker when libavdevice.so (from the JamaisMagic ffmpeg-kit-full-gpl AAR) is
# loaded on Android 15+ (API 35+), where the real PLATFORM_hid_write symbol is
# no longer available in the platform namespace.
add_library(hidapi_compat SHARED hidapi_compat.c)

set_target_properties(hidapi_compat PROPERTIES
    LINK_FLAGS "-Wl,-z,max-page-size=16384 -Wl,-z,common-page-size=16384"
)

# dl  — for dlopen / dladdr
# log — for __android_log_print
target_link_libraries(hidapi_compat dl log)
