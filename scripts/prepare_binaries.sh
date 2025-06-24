#!/bin/bash

# Prepare and package built binaries for distribution
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
VERSION="6.0.2-hw"
DIST_DIR="dist"
RELEASE_DIR="releases"

# Create distribution directories
mkdir -p $DIST_DIR
mkdir -p $RELEASE_DIR

# Function to package Android binaries
package_android() {
    echo -e "${BLUE}Packaging Android binaries...${NC}"
    
    if [ -d "output_android_hw" ]; then
        cd output_android_hw
        
        # Find AAR files
        AAR_FILES=$(find . -name "*.aar" -type f)
        
        if [ -n "$AAR_FILES" ]; then
            for aar in $AAR_FILES; do
                echo -e "${YELLOW}Found AAR: $aar${NC}"
                cp "$aar" "../$DIST_DIR/ffmpeg-kit-android-full-gpl-hw-$VERSION.aar"
            done
        else
            echo -e "${YELLOW}No AAR files found in output_android_hw${NC}"
        fi
        
        cd ..
    else
        echo -e "${YELLOW}Android output directory not found${NC}"
    fi
}

# Function to package iOS binaries
package_ios() {
    echo -e "${BLUE}Packaging iOS binaries...${NC}"
    
    if [ -d "output_ios_hw" ]; then
        cd output_ios_hw
        
        # Find framework directories
        FRAMEWORK_DIRS=$(find . -name "*.framework" -type d)
        
        if [ -n "$FRAMEWORK_DIRS" ]; then
            echo -e "${YELLOW}Found frameworks:${NC}"
            for framework in $FRAMEWORK_DIRS; do
                echo -e "${YELLOW}  - $framework${NC}"
            done
            
            # Create iOS framework package
            tar -czf "../$DIST_DIR/ffmpeg-kit-ios-full-gpl-hw-$VERSION.tar.gz" .
        else
            echo -e "${YELLOW}No framework directories found in output_ios_hw${NC}"
        fi
        
        cd ..
    else
        echo -e "${YELLOW}iOS output directory not found${NC}"
    fi
}

# Function to package macOS binaries
package_macos() {
    echo -e "${BLUE}Packaging macOS binaries...${NC}"
    
    if [ -d "output_macos_hw" ]; then
        cd output_macos_hw
        
        # Find framework directories
        FRAMEWORK_DIRS=$(find . -name "*.framework" -type d)
        
        if [ -n "$FRAMEWORK_DIRS" ]; then
            echo -e "${YELLOW}Found frameworks:${NC}"
            for framework in $FRAMEWORK_DIRS; do
                echo -e "${YELLOW}  - $framework${NC}"
            done
            
            # Create macOS framework package
            tar -czf "../$DIST_DIR/ffmpeg-kit-macos-full-gpl-hw-$VERSION.tar.gz" .
        else
            echo -e "${YELLOW}No framework directories found in output_macos_hw${NC}"
        fi
        
        cd ..
    else
        echo -e "${YELLOW}macOS output directory not found${NC}"
    fi
}

# Main packaging process
echo -e "${YELLOW}Starting packaging process...${NC}"

# Package all platforms
package_android
package_ios
package_macos

# Create release notes
cat > $DIST_DIR/RELEASE_NOTES.md << EOF
# FFmpeg Kit with Hardware Acceleration - v$VERSION

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

## Build Information
- FFmpeg Version: 6.0.2
- Build Date: $(date)
- Hardware Acceleration: Enabled
EOF

echo -e "${GREEN}=== Packaging completed! ===${NC}"
echo -e "${GREEN}Packaged files are in: $DIST_DIR/${NC}"
echo -e "${GREEN}Release notes: $DIST_DIR/RELEASE_NOTES.md${NC}"

# List packaged files
echo -e "${BLUE}=== Packaged Files ===${NC}"
ls -la $DIST_DIR/ 