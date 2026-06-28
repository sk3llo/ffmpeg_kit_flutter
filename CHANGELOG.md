## 2.1.0

* Added **Windows** support (x86_64) for the `video` FFmpeg 8.0 variant (video-codec set: dav1d, fontconfig, freetype, fribidi, kvazaar, libass, libiconv, libtheora, libvpx, libwebp, snappy).
* Native libraries are downloaded automatically at build time from the `8.0.0-video` release (`ffmpeg-kit-windows-x86_64-video-8.0.0.zip`); for local development point `FFMPEGKIT_LOCAL_DIR` (CMake cache var or environment) at a locally built bundle.
* The bundled MinGW DLLs are rebased/ASLR-adjusted at build time so the plugin loads standalone.
* Shell scripts are forced to LF via `.gitattributes` so the published package never carries Windows CRLF line endings (avoids the iOS/macOS `pod install` `/bin/bash^M: bad interpreter` failure).

## 2.0.0

* Upgraded FFmpeg to `v8.0.0`
* Updated Android `ffmpeg-kit-full` dependency to `2.1.0`
* Bumped iOS deployment target to `13.0`
* Bumped macOS deployment target to `10.15`
* Updated package version to `2.0.0` and updated README.md
* Updated zimg example command
* Updated `setup_ios.sh` and `setup_macos.sh` scripts to use `v8.0.0` and unzip to a `Frameworks` directory

## 1.1.0

* Upgraded `freetype` from **2.13.0** to **2.13.3**
* Upgraded `harfbuzz` from **8.0.1** to **11.3.3**
* Upgraded `fontconfig` from **2.16.2** to 2.17.1
* Added support for `harfbuzz` library in order to support `drawtext` filter
* Fixed missing `libunibreak` for `libass.sh`

## 1.0.1

* Updated README.md

## 1.0.0

* Initial release
* FFmpeg version 7.1.1
* Removed bundled Android FFmpeg (jniLibs, cpp, bindings)
* Added FFmpeg min using new Maven Central package