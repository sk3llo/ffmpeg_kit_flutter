#!/bin/bash

# Prepare and package built binaries for distribution - IMPROVED VERSION
# This script packages the built FFmpeg Kit binaries with hardware acceleration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Prepare FFmpeg Kit Binaries with Hardware Acceleration ===${NC}"

# Configuration
VERSION="6.0-hw"
ANDROID_VERSION="7.0-hw"
DIST_DIR="dist"
RELEASE_DIR="releases"

# Store the original directory
ORIGINAL_DIR=$(pwd)

# Create distribution directories
mkdir -p $DIST_DIR
mkdir -p $RELEASE_DIR

# Function to package Android binaries - ONLY AAR file
package_android() {
    echo -e "${BLUE}Packaging Android binaries (AAR only)...${NC}"
    
    if [ -d "output_android_hw/bundle-android-aar" ]; then
        cd output_android_hw/bundle-android-aar
        
        # Only package the AAR file
        if [ -f "ffmpeg-kit/ffmpeg-kit.aar" ]; then
            echo -e "${YELLOW}Found AAR: ffmpeg-kit/ffmpeg-kit.aar${NC}"
            cp "ffmpeg-kit/ffmpeg-kit.aar" "../../$DIST_DIR/ffmpeg-kit-android-full-gpl-hw-$ANDROID_VERSION.aar"
            echo -e "${GREEN}Android AAR packaged successfully${NC}"
        else
            echo -e "${YELLOW}No AAR files found in output_android_hw${NC}"
        fi
        
        cd "$ORIGINAL_DIR"
    else
        echo -e "${YELLOW}Android output directory not found${NC}"
    fi
}

# Function to package iOS binaries - ONLY framework bundles
package_ios() {
    echo -e "${BLUE}Packaging iOS binaries (frameworks only)...${NC}"
    
    if [ -d "output_ios_hw/bundle-apple-framework-ios" ]; then
        cd output_ios_hw/bundle-apple-framework-ios
        
        # Create temporary directory for clean packaging
        TEMP_DIR="../../$DIST_DIR/ios_temp"
        mkdir -p "$TEMP_DIR"
        
        # Only copy framework directories (not build artifacts)
        FRAMEWORK_DIRS=$(find . -name "*.framework" -type d)
        
        if [ -n "$FRAMEWORK_DIRS" ]; then
            echo -e "${YELLOW}Found frameworks:${NC}"
            for framework in $FRAMEWORK_DIRS; do
                echo -e "${YELLOW}  - $framework${NC}"
                # Copy only the framework directory
                cp -r "$framework" "$TEMP_DIR/"
            done
            
            # Create iOS framework package from clean directory
            cd "$TEMP_DIR"
            zip -r "../ffmpeg-kit-ios-full-gpl-hw-$VERSION.zip" .
            cd "$ORIGINAL_DIR"
            
            # Clean up temporary directory
            rm -rf "$TEMP_DIR"
            
            echo -e "${GREEN}iOS frameworks packaged successfully${NC}"
        else
            echo -e "${YELLOW}No framework directories found in output_ios_hw${NC}"
            cd "$ORIGINAL_DIR"
        fi
    else
        echo -e "${YELLOW}iOS output directory not found${NC}"
    fi
}

# Function to package macOS binaries - ONLY framework bundles
package_macos() {
    echo -e "${BLUE}Packaging macOS binaries (frameworks only)...${NC}"
    
    if [ -d "output_macos_hw/bundle-apple-framework-macos" ]; then
        cd output_macos_hw/bundle-apple-framework-macos
        
        # Create temporary directory for clean packaging
        TEMP_DIR="../../$DIST_DIR/macos_temp"
        mkdir -p "$TEMP_DIR"
        
        # Only copy framework directories (not build artifacts)
        FRAMEWORK_DIRS=$(find . -name "*.framework" -type d)
        
        if [ -n "$FRAMEWORK_DIRS" ]; then
            echo -e "${YELLOW}Found frameworks:${NC}"
            for framework in $FRAMEWORK_DIRS; do
                echo -e "${YELLOW}  - $framework${NC}"
                # Copy only the framework directory
                cp -r "$framework" "$TEMP_DIR/"
            done
            
            # Create macOS framework package from clean directory
            cd "$TEMP_DIR"
            zip -r "../ffmpeg-kit-macos-full-gpl-hw-$VERSION.zip" .
            cd "$ORIGINAL_DIR"
            
            # Clean up temporary directory
            rm -rf "$TEMP_DIR"
            
            echo -e "${GREEN}macOS frameworks packaged successfully${NC}"
        else
            echo -e "${YELLOW}No framework directories found in output_macos_hw${NC}"
            cd "$ORIGINAL_DIR"
        fi
    else
        echo -e "${YELLOW}macOS output directory not found${NC}"
    fi
}

# Main packaging process
echo -e "${YELLOW}Starting packaging process...${NC}"

# Package all platforms with only necessary files
package_android
package_ios
package_macos

# Ensure dist directory exists before creating release notes
if [ ! -d "$DIST_DIR" ]; then
    echo -e "${RED}Error: $DIST_DIR directory does not exist${NC}"
    exit 1
fi

# Create release notes
cat > $DIST_DIR/RELEASE_NOTES.md << EOF
# FFmpeg Kit with Hardware Acceleration - ios/macos: v$VERSION - android: v$ANDROID_VERSION

## Package Contents

### Android Package
- **File**: ffmpeg-kit-android-full-gpl-hw-$ANDROID_VERSION.aar
- **Contents**: Single AAR file with all architectures (arm, arm64, x86, x86_64)
- **Size**: Optimized to include only necessary libraries

### iOS Package
- **File**: ffmpeg-kit-ios-full-gpl-hw-$VERSION.zip
- **Contents**: Framework bundles only (no build artifacts)
- **Frameworks**: ffmpegkit, libavcodec, libavdevice, libavfilter, libavformat, libavutil, libswresample, libswscale

### macOS Package
- **File**: ffmpeg-kit-macos-full-gpl-hw-$VERSION.zip
- **Contents**: Framework bundles only (no build artifacts)
- **Frameworks**: ffmpegkit, libavcodec, libavdevice, libavfilter, libavformat, libavutil, libswresample, libswscale

## Hardware Acceleration Support

### Android
- **MediaCodec**: H.264/AVC, H.265/HEVC, MPEG-2, MPEG-4, VP8, VP9, AV1
- **Requirements**: Android API Level 24+

### iOS
- **VideoToolbox**: H.264/AVC, H.265/HEVC, MPEG-2, MPEG-4, VP8, VP9, AV1
- **Requirements**: iOS 14.0+

### macOS
- **VideoToolbox**: H.264/AVC, H.265/HEVC, MPEG-2, MPEG-4, VP8, VP9, AV1
- **Requirements**: macOS 10.15+

## Usage Examples

### Android (MediaCodec)
\`\`\`dart
// Encode with MediaCodec
FFmpegKit.execute('-i input.mp4 -c:v h264_mediacodec -b:v 2M output.mp4');

// Decode with MediaCodec
FFmpegKit.execute('-i input.mp4 -c:v h264_mediacodec -f null -');
\`\`\`

### iOS/macOS (VideoToolbox)
\`\`\`dart
// Encode with VideoToolbox
FFmpegKit.execute('-i input.mp4 -c:v h264_videotoolbox -b:v 2M output.mp4');

// Decode with VideoToolbox
FFmpegKit.execute('-i input.mp4 -c:v h264_videotoolbox -f null -');
\`\`\`

## Optimization Notes
- Removed build artifacts and intermediate files
- Included only framework bundles for Apple platforms
- Single AAR file for Android with all architectures
- Reduced package sizes significantly
- Maintained all functionality while minimizing footprint

## Build Information
- FFmpeg iOS/macOS Version: 6.0.2
- FFmpeg Android Version: 7.0
- Build Date: $(date)
- Hardware Acceleration: Enabled
- Package Optimization: Enabled
EOF

echo -e "${GREEN}=== Packaging completed! ===${NC}"
echo -e "${GREEN}Packaged files are in: $DIST_DIR/${NC}"
echo -e "${GREEN}Release notes: $DIST_DIR/RELEASE_NOTES.md${NC}"

# List packaged files
echo -e "${BLUE}=== Packaged Files ===${NC}"
ls -la $DIST_DIR/ 