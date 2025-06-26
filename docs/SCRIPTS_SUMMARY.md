# Scripts Summary - FFmpeg Kit Flutter Hardware Acceleration

## 📋 Quick Reference

| Script | Purpose | Platform | Output |
|--------|---------|----------|---------|
| `setup_android.sh` | Download Android AAR | Android | `android/libs/ffmpegkit.aar` |
| `setup_ios.sh` | Download iOS frameworks | iOS | `ios/Frameworks/` |
| `setup_macos.sh` | Download macOS frameworks | macOS | `macos/Frameworks/` |
| `build_android_hw.sh` | Build Android from source | Android | `output_android_hw/` |
| `build_ios_hw.sh` | Build iOS from source | iOS | `output_ios_hw/` |
| `build_macos_hw.sh` | Build macOS from source | macOS | `output_macos_hw/` |
| `build_all_hw.sh` | Build all platforms | All | Multiple output dirs |
| `prepare_binaries.sh` | Package for distribution | All | `dist/` |

## 🚀 Quick Start Commands

### Option 1: Use Pre-built Binaries (Recommended)
```bash
# Setup all platforms
./scripts/setup_android.sh
./scripts/setup_ios.sh
./scripts/setup_macos.sh

# Test immediately
cd example && flutter run
```

### Option 2: Build from Source
```bash
# Build all platforms
./scripts/build_all_hw.sh

# Package for distribution
./scripts/prepare_binaries.sh
```

### Option 3: Individual Platform Builds
```bash
# Android only
./scripts/build_android_hw.sh

# iOS only
./scripts/build_ios_hw.sh

# macOS only
./scripts/build_macos_hw.sh
```

## 🔧 Requirements

### Android Build Requirements
- Android SDK (API level 24+)
- Android NDK (r21+)
- Environment variables: `ANDROID_SDK_ROOT`, `ANDROID_NDK_ROOT`

### iOS/macOS Build Requirements
- macOS with Xcode 12+
- iOS 14.0+ SDK / macOS 10.15+ SDK
- Command Line Tools

### General Requirements
- Git, Make, Autotools, pkg-config, NASM

## 📦 Output Structure

### Build Outputs
```
output_android_hw/          # Android binaries
├── bundle-android-aar/
│   └── ffmpeg-kit/
│       └── ffmpeg-kit.aar

output_ios_hw/              # iOS binaries
└── bundle-apple-framework-ios/
    ├── ffmpegkit.framework/
    ├── libavcodec.framework/
    └── ... (other frameworks)

output_macos_hw/            # macOS binaries
└── bundle-apple-framework-macos/
    ├── ffmpegkit.framework/
    ├── libavcodec.framework/
    └── ... (other frameworks)
```

### Distribution Outputs
```
dist/                       # Packaged binaries
├── ffmpeg-kit-android-full-gpl-hw-7.0-hw.aar
├── ffmpeg-kit-ios-full-gpl-hw-6.0-hw.zip
├── ffmpeg-kit-macos-full-gpl-hw-6.0-hw.zip
└── RELEASE_NOTES.md
```

## 🎯 Hardware Acceleration Features

### Android (MediaCodec)
- **Supported Codecs**: H.264, H.265, VP8, VP9, AV1
- **Performance**: 2-10x faster than software
- **Requirements**: Android API Level 24+

### iOS/macOS (VideoToolbox)
- **Supported Codecs**: H.264, H.265, MPEG-2, MPEG-4, VP8, VP9, AV1
- **Performance**: 2-8x faster than software
- **Requirements**: iOS 14.0+, macOS 10.15+

## 🔄 Workflow Examples

### Development Workflow
```bash
# 1. Setup environment
export ANDROID_SDK_ROOT=/path/to/android/sdk
export ANDROID_NDK_ROOT=/path/to/android/ndk

# 2. Build all platforms
./scripts/build_all_hw.sh

# 3. Package for distribution
./scripts/prepare_binaries.sh

# 4. Test
cd example && flutter run
```

### Quick Testing Workflow
```bash
# 1. Download pre-built binaries
./scripts/setup_android.sh
./scripts/setup_ios.sh
./scripts/setup_macos.sh

# 2. Test immediately
cd example && flutter run
```

### Custom Build Workflow
```bash
# 1. Build specific platform
./scripts/build_android_hw.sh

# 2. Customize build flags
# Edit generated android_hw.sh script

# 3. Rebuild
cd ffmpeg-kit && ./android_hw.sh

# 4. Package
cd .. && ./scripts/prepare_binaries.sh
```

## 🚨 Common Issues & Solutions

### Permission Issues
```bash
chmod +x scripts/*.sh
```

### Missing Dependencies
```bash
# Android
brew install android-sdk android-ndk

# iOS/macOS
xcode-select --install
```

### Environment Variables
```bash
# Check Android environment
echo $ANDROID_SDK_ROOT
echo $ANDROID_NDK_ROOT

# Check iOS/macOS environment
xcode-select --print-path
```

### Clean Build
```bash
# Remove all build artifacts
rm -rf output_* ffmpeg-kit dist releases
```

## 📝 Configuration

### Version Configuration
```bash
# Edit in scripts
FFMPEG_KIT_VERSION="v6.0.LTS"
VERSION="6.0-hw"
ANDROID_VERSION="7.0-hw"
```

### Custom URLs (for own hosting)
```bash
# Edit in setup scripts
ANDROID_URL="https://your-repo.com/ffmpeg-kit-android-hw.aar"
IOS_URL="https://your-repo.com/ffmpeg-kit-ios-hw.zip"
MACOS_URL="https://your-repo.com/ffmpeg-kit-macos-hw.zip"
```

## 🧪 Testing

### Hardware Acceleration Detection
```dart
FFmpegKit.execute('-encoders').then((session) async {
  final output = await session.getOutput();
  if (output.contains('h264_mediacodec') || output.contains('h264_videotoolbox')) {
    print('Hardware acceleration available!');
  }
});
```

### Performance Testing
```dart
final stopwatch = Stopwatch()..start();
await FFmpegKit.execute('-i input.mp4 -c:v ${getHardwareCodec()} output.mp4');
stopwatch.stop();
print('Encoding time: ${stopwatch.elapsedMilliseconds}ms');
```

## 📚 Documentation

- [Detailed Scripts Guide](SCRIPTS_GUIDE.md) - Complete documentation
- [Hardware Acceleration Guide](../README_HARDWARE.md) - Hardware features
- [Build Guide](BUILD_GUIDE.md) - Build instructions

## 🤝 Contributing

When adding new scripts:
1. Follow naming conventions
2. Include error handling
3. Add documentation
4. Test thoroughly
5. Update this summary

## 📄 License

This project is licensed under LGPL 3.0 with GPL v3.0 components for hardware acceleration features. 