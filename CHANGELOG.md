## 3.2.0

* Added **Windows** support (x86_64) for the `min` FFmpeg 8.0 variant (bare FFmpeg, no external libraries, no GPL components).
* Native libraries are downloaded automatically at build time from the `8.0.0-min` release (`ffmpeg-kit-windows-x86_64-min-8.0.0.zip`); for local development point `FFMPEGKIT_LOCAL_DIR` (CMake cache var or environment) at a locally built bundle.
* The bundled MinGW DLLs are rebased/ASLR-adjusted at build time and the full runtime dependency closure is shipped so the plugin loads standalone.
* Shell scripts are forced to LF via `.gitattributes` so the published package never carries Windows CRLF line endings (avoids the iOS/macOS `pod install` `/bin/bash^M: bad interpreter` failure).

## 3.1.0

* Added ProGuard rules
* Fixed the FFmpeg 8.0 compatibility issue across all platforms. The problem was that `all_channel_counts` was being set AFTER the filter was created, but FFmpeg 8.0 requires it to be set DURING filter creation.

## 3.0.0

* FFmpeg `v8.0.0` with [all the sweet perks](https://ffmpeg.org/index.html#news)

## 2.1.0

* Downgraded Kotlin from 2.2.0 to 1.8.22
* Added new jniLibs that support Kotlin 1.8

## 2.0.0

* Removed bundled Android FFmpeg (jniLibs, cpp, bindings)
* Added FFmpeg min using new Maven Central package

## 1.0.1

* Updated README.md
* Updated scripts

## 1.0.0

* Initial release
* FFmpeg version 7.1.1