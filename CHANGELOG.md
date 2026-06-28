## 2.2.0

* Added **Windows** support (x86_64) for the `min-gpl` FFmpeg 8.0 variant (bare FFmpeg plus the four GPL video libraries: `x264`, `x265`, `xvid`, `vid.stab`).
* Native libraries are downloaded automatically at build time from the `8.0.0-min-gpl` release (`ffmpeg-kit-windows-x86_64-min-gpl-8.0.0.zip`); for local development point `FFMPEGKIT_LOCAL_DIR` (CMake cache var or environment) at a locally built bundle.
* The bundled MinGW DLLs are rebased/ASLR-adjusted at build time and the full runtime dependency closure is shipped so the plugin loads standalone.
* Shell scripts are forced to LF via `.gitattributes` so the published package never carries Windows CRLF line endings (avoids the iOS/macOS `pod install` `/bin/bash^M: bad interpreter` failure).

## 2.1.1

* Added ProGuard rules to support release builds
* Enabled ProGuard for Android release builds

## 2.1.0

* Fixed the FFmpeg 8.0 compatibility issue across all platforms. The problem was that `all_channel_counts` was being set AFTER the filter was created, but FFmpeg 8.0 requires it to be set DURING filter creation.

## 2.0.0

* FFmpeg `v8.0.0` with [all the sweet perks](https://ffmpeg.org/index.html#news)

## 1.1.0

* Added proguard-rules.pro to keep `ffmpeg` dependencies when minification is enabled
* Upgraded `freetype` from **2.13.0** to **2.13.3**
* Upgraded `harfbuzz` from **8.0.1** to **11.3.3**
* Upgraded `fontconfig` from **2.16.2** to 2.17.1
* Added support for `harfbuzz` library in order to support `drawtext` filter
* Fixed missing `libunibreak` for `libass.sh`
* Downgraded required Kotlin version to `v1.8.22`
* Upgraded com.android.library from `8.11.1` to `8.12.0`

## 1.0.0

* Initial release
* FFmpeg version 7.1.1
* Removed bundled Android FFmpeg (jniLibs, cpp, bindings)
* Added FFmpeg min using new Maven Central package