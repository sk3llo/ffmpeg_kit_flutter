# Scripts Guide - FFmpeg Kit Flutter Hardware Acceleration

This guide provides detailed information about all the scripts available in the `scripts/` directory for building, setting up, and packaging FFmpeg Kit Flutter with hardware acceleration support.

## 📁 Scripts Overview

The project includes several categories of scripts:

### Setup Scripts
Scripts for downloading and setting up pre-built binaries with hardware acceleration support.

### Build Scripts
Scripts for building FFmpeg Kit from source with hardware acceleration enabled.

### Packaging Scripts
Scripts for packaging built binaries for distribution.

## 🚀 Setup Scripts

### `setup_android.sh`

Downloads and sets up Android AAR with MediaCodec support.

**Purpose:**
- Downloads pre-built Android AAR with hardware acceleration
- Places AAR in the correct location for Flutter integration
- Configures Android project for MediaCodec support

**Usage:**
```bash
./scripts/setup_android.sh
```

**Configuration:**
```bash
# Configuration variables (edit as needed)
VERSION="7.0-hw"
ANDROID_URL="https://github.com/Gperez88/ffmpeg_kit_flutter/releases/download/6.0-hw/ffmpeg-kit-android-full-gpl-hw-7.0-hw.aar"
```

**Output:**
- Downloads AAR to `android/libs/com.arthenica.ffmpegkit-flutter-7.0.aar`

### `setup_ios.sh`

Downloads and sets up iOS frameworks with VideoToolbox support.

**Purpose:**
- Downloads pre-built iOS frameworks with hardware acceleration
- Extracts frameworks to the correct location
- Removes bitcode for App Store compliance

**Usage:**
```bash
./scripts/setup_ios.sh
```

**Configuration:**
```bash
# Configuration variables (edit as needed)
VERSION="6.0-hw"
IOS_URL="https://github.com/Gperez88/ffmpeg_kit_flutter/releases/download/6.0-hw/ffmpeg-kit-ios-full-gpl-hw-6.0-hw.zip"
```

**Output:**
- Downloads and extracts frameworks to `ios/Frameworks/`
- Automatically strips bitcode from all frameworks

### `setup_macos.sh`

Downloads and sets up macOS frameworks with VideoToolbox support.

**Purpose:**
- Downloads pre-built macOS frameworks with hardware acceleration
- Extracts frameworks to the correct location
- Removes bitcode for distribution

**Usage:**
```bash
./scripts/setup_macos.sh
```

**Configuration:**
```bash
# Configuration variables (edit as needed)
VERSION="6.0-hw"
MACOS_URL="https://github.com/Gperez88/ffmpeg_kit_flutter/releases/download/6.0-hw/ffmpeg-kit-macos-full-gpl-hw-6.0-hw.zip"
```

**Output:**
- Downloads and extracts frameworks to `macos/Frameworks/`
- Automatically strips bitcode from all frameworks

## 🔨 Build Scripts

### `build_android_hw.sh`

Builds Android binaries with MediaCodec hardware acceleration support.

**Purpose:**
- Clones FFmpeg Kit repository
- Configures build with MediaCodec support
- Builds optimized Android AAR

**Requirements:**
- Android SDK (API level 24+)
- Android NDK (r21+)
- Environment variables: `ANDROID_SDK_ROOT`, `ANDROID_NDK_ROOT`

**Usage:**
```bash
./scripts/build_android_hw.sh
```

**Features:**
- MediaCodec hardware acceleration
- WebP support
- H.264 encoding (x264)
- H.265 encoding (x265)
- GPL license compliance

**Output:**
- Built artifacts in `output_android_hw/`
- AAR file with all architectures

**Customization:**
```bash
# Edit build configuration
FFMPEG_KIT_VERSION="v6.0.LTS"
OUTPUT_DIR="output_android_hw"

# Modify build flags in the generated android_hw.sh script
```

### `build_ios_hw.sh`

Builds iOS binaries with VideoToolbox hardware acceleration support.

**Purpose:**
- Clones FFmpeg Kit repository
- Configures build with VideoToolbox support
- Builds optimized iOS frameworks

**Requirements:**
- macOS with Xcode 12+
- iOS 14.0+ SDK
- Command Line Tools

**Usage:**
```bash
./scripts/build_ios_hw.sh
```

**Features:**
- VideoToolbox hardware acceleration
- WebP support
- H.264 encoding (x264)
- H.265 encoding (x265)
- GPL license compliance

**Output:**
- Built artifacts in `output_ios_hw/`
- Framework bundles for all architectures

**Customization:**
```bash
# Edit build configuration
FFMPEG_KIT_VERSION="v6.0.LTS"
OUTPUT_DIR="output_ios_hw"

# Modify build flags in the generated ios_hw.sh script
```

### `build_macos_hw.sh`

Builds macOS binaries with VideoToolbox hardware acceleration support.

**Purpose:**
- Clones FFmpeg Kit repository
- Configures build with VideoToolbox support
- Builds optimized macOS frameworks

**Requirements:**
- macOS with Xcode 12+
- macOS 10.15+ SDK
- Command Line Tools

**Usage:**
```bash
./scripts/build_macos_hw.sh
```

**Features:**
- VideoToolbox hardware acceleration
- WebP support
- H.264 encoding (x264)
- H.265 encoding (x265)
- GPL license compliance

**Output:**
- Built artifacts in `output_macos_hw/`
- Framework bundles for all architectures

**Customization:**
```bash
# Edit build configuration
FFMPEG_KIT_VERSION="v6.0.LTS"
OUTPUT_DIR="output_macos_hw"

# Modify build flags in the generated macos_hw.sh script
```

### `build_all_hw.sh`

Builds all platforms with hardware acceleration support.

**Purpose:**
- Automatically detects available build environments
- Builds for all supported platforms
- Provides comprehensive build summary

**Usage:**
```bash
./scripts/build_all_hw.sh
```

**Features:**
- Automatic platform detection
- Conditional building based on available tools
- Comprehensive build summary
- Hardware acceleration verification

**Output:**
- Built artifacts in respective output directories
- Summary of all builds and features

**Platform Detection:**
```bash
# Android detection
command_exists adb

# iOS/macOS detection
[[ "$OSTYPE" == "darwin"* ]] && command_exists xcodebuild
```

## 📦 Packaging Scripts

### `prepare_binaries.sh`

Packages built binaries for distribution.

**Purpose:**
- Creates optimized distribution packages
- Removes build artifacts and intermediate files
- Generates release notes and documentation

**Usage:**
```bash
./scripts/prepare_binaries.sh
```

**Features:**
- Optimized package sizes
- Clean framework bundles
- Single AAR file for Android
- Comprehensive release notes

**Output:**
- `dist/` directory with packaged binaries
- `RELEASE_NOTES.md` with detailed information

**Package Contents:**

**Android Package:**
- File: `ffmpeg-kit-android-full-gpl-hw-7.0-hw.aar`
- Contents: Single AAR file with all architectures
- Optimization: Removed build artifacts, minimal footprint

**iOS Package:**
- File: `ffmpeg-kit-ios-full-gpl-hw-6.0-hw.zip`
- Contents: Framework bundles only
- Frameworks: ffmpegkit, libavcodec, libavdevice, libavfilter, libavformat, libavutil, libswresample, libswscale

**macOS Package:**
- File: `ffmpeg-kit-macos-full-gpl-hw-6.0-hw.zip`
- Contents: Framework bundles only
- Frameworks: Same as iOS

## 🔧 Script Customization

### Environment Variables

Set these environment variables for build scripts:

```bash
# Android
export ANDROID_SDK_ROOT=/path/to/android/sdk
export ANDROID_NDK_ROOT=/path/to/android/ndk

# Verify setup
echo $ANDROID_SDK_ROOT
echo $ANDROID_NDK_ROOT
```

### Build Configuration

Modify build parameters in scripts:

```bash
# Version configuration
FFMPEG_KIT_VERSION="v6.0.LTS"
VERSION="6.0-hw"
ANDROID_VERSION="7.0-hw"

# Output directories
OUTPUT_DIR="output_android_hw"
DIST_DIR="dist"
RELEASE_DIR="releases"
```

### Custom Build Flags

Add custom build flags to generated scripts:

```bash
# Android custom flags
./android.sh \
  --enable-gpl \
  --enable-android-media-codec \
  --enable-libwebp \
  --enable-x264 \
  --enable-x265 \
  --enable-custom-flag

# iOS/macOS custom flags
./ios.sh \
  --enable-gpl \
  --enable-ios-videotoolbox \
  --enable-libwebp \
  --enable-x264 \
  --enable-x265 \
  --enable-custom-flag
```

## 🚨 Troubleshooting

### Common Issues

**Permission Denied:**
```bash
chmod +x scripts/*.sh
```

**Missing Dependencies:**
```bash
# Android
brew install android-sdk android-ndk

# iOS/macOS
xcode-select --install
```

**Environment Variables:**
```bash
# Check Android environment
echo $ANDROID_SDK_ROOT
echo $ANDROID_NDK_ROOT

# Check iOS/macOS environment
xcode-select --print-path
xcrun --show-sdk-path
```

**Network Issues:**
```bash
# Check internet connection
curl -I https://github.com

# Use custom URLs in setup scripts
```

### Debug Mode

Enable debug output in scripts:

```bash
# Add to script beginning
set -x

# Or run with debug
bash -x ./scripts/build_android_hw.sh
```

### Clean Build

Clean previous builds:

```bash
# Remove output directories
rm -rf output_android_hw output_ios_hw output_macos_hw

# Remove FFmpeg Kit repository
rm -rf ffmpeg-kit

# Clean distribution
rm -rf dist releases
```

## 📋 Script Dependencies

### Required Tools

**All Platforms:**
- Git
- Make
- Autotools
- pkg-config
- NASM

**Android:**
- Android SDK (API level 24+)
- Android NDK (r21+)
- Java 8 or higher
- CMake 3.10.2 or higher

**iOS/macOS:**
- Xcode 12+ with Command Line Tools
- iOS 14.0+ SDK
- macOS 10.15+ SDK

### Optional Tools

**Development:**
- Docker (for isolated builds)
- Virtual machines (for cross-platform builds)
- CI/CD tools (for automated builds)

## 🔄 Workflow Examples

### Complete Development Workflow

```bash
# 1. Setup environment
export ANDROID_SDK_ROOT=/path/to/android/sdk
export ANDROID_NDK_ROOT=/path/to/android/ndk

# 2. Build all platforms
./scripts/build_all_hw.sh

# 3. Package for distribution
./scripts/prepare_binaries.sh

# 4. Test the build
cd example
flutter run
```

### Quick Setup Workflow

```bash
# 1. Download pre-built binaries
./scripts/setup_android.sh
./scripts/setup_ios.sh
./scripts/setup_macos.sh

# 2. Test immediately
cd example
flutter run
```

### Custom Build Workflow

```bash
# 1. Build specific platform
./scripts/build_android_hw.sh

# 2. Customize build flags
# Edit the generated android_hw.sh script

# 3. Rebuild
cd ffmpeg-kit
./android_hw.sh

# 4. Package
cd ..
./scripts/prepare_binaries.sh
```

## 📝 Best Practices

### Script Organization

1. **Keep scripts modular** - Each script has a single responsibility
2. **Use consistent naming** - All scripts follow the same naming convention
3. **Include error handling** - Scripts exit on errors with helpful messages
4. **Add documentation** - Each script includes usage information

### Build Optimization

1. **Use pre-built binaries** when possible for faster setup
2. **Build from source** for custom configurations
3. **Clean builds** regularly to avoid conflicts
4. **Test builds** on target platforms

### Distribution

1. **Optimize package sizes** by removing unnecessary files
2. **Include release notes** with detailed information
3. **Version packages** consistently
4. **Test packages** before distribution

## 🤝 Contributing

When adding new scripts:

1. **Follow naming conventions** - Use descriptive names with platform suffixes
2. **Include error handling** - Check prerequisites and exit gracefully
3. **Add documentation** - Include usage examples and requirements
4. **Test thoroughly** - Verify on target platforms
5. **Update this guide** - Document new scripts and features

## 📚 Additional Resources

- [FFmpeg Kit Wiki](https://github.com/arthenica/ffmpeg-kit/wiki)
- [FFmpeg Documentation](https://ffmpeg.org/documentation.html)
- [Android MediaCodec](https://developer.android.com/reference/android/media/MediaCodec)
- [iOS VideoToolbox](https://developer.apple.com/documentation/videotoolbox)
- [Build Guide](BUILD_GUIDE.md)
- [Hardware Acceleration Guide](../README_HARDWARE.md) 