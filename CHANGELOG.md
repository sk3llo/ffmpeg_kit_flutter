## 2.4.0

* Updated **FFmpeg to v8.1.1** (arthenica `n8.1.1`), up from 8.0.0.
* iOS/macOS `.xcframework`s, the Android Maven library (`com.antonkarpenko:ffmpeg-kit-*`), and the Windows binaries are now built against FFmpeg 8.1.1.

## 2.3.2

* Android: broadened the bundled ProGuard/R8 consumer rules to keep **all** `com.antonkarpenko.ffmpegkit.**` classes (plus `-dontwarn`), not just the JNI entry points. Fully prevents R8 from stripping FFmpegKit in release builds — fixes the release-only white screen / `channel-error` (FFmpegKit failing to initialise, which cascades into errors like `shared_preferences` `getAll`). Closes #158.

## 2.3.1

* Android: ship ProGuard/R8 **consumer rules** (`consumer-rules.pro`, applied automatically via `consumerProguardFiles`) that keep the FFmpegKit JNI bindings — `FFmpegKitConfig` native/callback methods and `AbiDetect`. Prevents release-mode crashes such as `Bad JNI version returned from JNI_OnLoad` without requiring any ProGuard rules in your app. Thanks @niclasEX (#133).

## 2.3.0

* Fixed **iOS Simulator on Apple Silicon** (`arm64`) support — required for Xcode 26 / iOS 26+ simulators. Builds previously failed with *"The following target(s) do not support arm64 architecture, which is a requirement for Apple Silicon iOS 26+ simulators"*.
* The downloaded iOS `.framework` bundles are now converted to `.xcframework`s at build time (`scripts/setup_ios.sh`), exposing a native `ios-arm64_x86_64-simulator` slice alongside the `ios-arm64_arm64e` device slice. The simulator `arm64` slice is produced by retagging the device `arm64` slice's Mach-O build-version platform to `iOS-Simulator` via `vtool`.
* The iOS podspec now vendors `.xcframework`s and no longer excludes `arm64` for the simulator (`EXCLUDED_ARCHS[sdk=iphonesimulator*]` is now `i386` only).
* If you previously added `config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"` to your app's `ios/Podfile` `post_install` hook as a workaround, **remove it** — it now prevents the simulator `arm64` slice from linking.

## 2.2.0

* Added **Windows** support (x86_64) for the `https` FFmpeg 8.0 variant (bare FFmpeg + the gnutls TLS stack: gmp + gnutls, enabling `https://` and other TLS protocols).
* Native libraries are downloaded automatically at build time from the `8.0.0-https` release (`ffmpeg-kit-windows-x86_64-https-8.0.0.zip`); for local development point `FFMPEGKIT_LOCAL_DIR` (CMake cache var or environment) at a locally built bundle.
* The bundled MinGW DLLs are rebased/ASLR-adjusted at build time and the full runtime dependency closure (gnutls/gmp/nettle/...) is shipped so the plugin loads standalone.
* Shell scripts are forced to LF via `.gitattributes` so the published package never carries Windows CRLF line endings (avoids the iOS/macOS `pod install` `/bin/bash^M: bad interpreter` failure).

## 2.1.0

* Fixed the FFmpeg 8.0 compatibility issue across all platforms. The problem was that `all_channel_counts` was being set AFTER the filter was created, but FFmpeg 8.0 requires it to be set DURING filter creation.

## 2.0.0

* FFmpeg `v8.0.0` with [all the sweet perks](https://ffmpeg.org/index.html#news)

## 1.1.1

* Updated `pubspec.yaml` description

## 1.1.0

* Added proguard-rules.pro to keep `ffmpeg` dependencies when minification is enabled
* Upgraded `freetype` from **2.13.0** to **2.13.3**
* Upgraded `harfbuzz` from **8.0.1** to **11.3.3**
* Upgraded `fontconfig` from **2.16.2** to 2.17.1
* Added support for `harfbuzz` library in order to support `drawtext` filter
* Fixed missing `libunibreak` for `libass.sh`
* Downgraded required Kotlin version to `v1.8.22`
* Upgraded com.android.library from `8.11.1` to `8.12.0`

## 1.0.2

* Fixed licencing in `README.md`
* Added link to `HTTPS-GPL` package
* Upgraded version in `ffpmpeg_kit_factory.dart`

## 1.0.1

* Updated repository URL and header
* Formatted code

## 1.0.0

* Initial release
* FFmpeg version 7.1.1
* Removed bundled Android FFmpeg (jniLibs, cpp, bindings)
* Added FFmpeg min using new Maven Central package