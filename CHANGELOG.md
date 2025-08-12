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