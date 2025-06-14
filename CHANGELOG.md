## 1.7.0

* Added updated arm64-v8a Android .so libraries, compatible with Google 16 KB requirement
* Updated `setup_ios.sh` script
* Removed resource shrinking for Android

## 1.6.1

* Removed manual packaging of prebuilt dependencies for Android
* Cleaned up unnecessary logs

## 1.6.0

* Added new seamless Android .aar support

## 1.5.0

* Added MacOS support by directly downloading and unpacking frameworks

## 1.4.1

* Updated README.md

## 1.4.0

* Added build.bat jni
* Updated Gradle script in order to be able to download and unpack .aar on Windows.

## 1.3.0

* Moved from FFmpeg `http` to `full_gpl` for Android
* Added downloading and unpacking of 6.0.2 `full-gpl` .aar

## 1.2.1

* Added displaying of Android platform to pub.dev
* Fixed static analysis issues

## 1.2.0

* New example project
* Resurrected Android by creating new `ffmpeg_kit_flutter_android` library with `com.arthenica:ffmpeg-kit-https:6.0-2.LTS` implementation
* iOS deployment target is increased to 14.0
* Upgraded plugin_platform_interface version

## 1.1.0

* Moved from `https` to `full-gpl` binding for MacOS
* Upgraded Flutter and Dart versions

## 1.0.0

* Initial release
* Fixed Android and MacOS bindings
* Upgraded FFmpegKitFlutterPlugin.java to work with Flutter 3.29