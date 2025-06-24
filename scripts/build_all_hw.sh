#!/bin/bash

# FFmpeg Kit Build All Platforms with Hardware Acceleration
# This script builds FFmpeg Kit for all platforms with hardware acceleration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== FFmpeg Kit Build All Platforms with Hardware Acceleration ===${NC}"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to build Android
build_android() {
    echo -e "${BLUE}=== Building Android with MediaCodec ===${NC}"
    if command_exists adb; then
        ./scripts/build_android_hw.sh
    else
        echo -e "${YELLOW}Android SDK not found, skipping Android build${NC}"
    fi
}

# Function to build iOS
build_ios() {
    echo -e "${BLUE}=== Building iOS with VideoToolbox ===${NC}"
    if [[ "$OSTYPE" == "darwin"* ]] && command_exists xcodebuild; then
        ./scripts/build_ios_hw.sh
    else
        echo -e "${YELLOW}macOS/Xcode not found, skipping iOS build${NC}"
    fi
}

# Function to build macOS
build_macos() {
    echo -e "${BLUE}=== Building macOS with VideoToolbox ===${NC}"
    if [[ "$OSTYPE" == "darwin"* ]] && command_exists xcodebuild; then
        ./scripts/build_macos_hw.sh
    else
        echo -e "${YELLOW}macOS/Xcode not found, skipping macOS build${NC}"
    fi
}

# Main build process
echo -e "${YELLOW}Starting builds for all platforms...${NC}"

# Build Android
build_android

# Build iOS
build_ios

# Build macOS
build_macos

echo -e "${GREEN}=== All builds completed! ===${NC}"
echo -e "${GREEN}Check the output directories for built artifacts:${NC}"
echo -e "${GREEN}  - Android: output_android_hw/${NC}"
echo -e "${GREEN}  - iOS: output_ios_hw/${NC}"
echo -e "${GREEN}  - macOS: output_macos_hw/${NC}"

# Create summary
echo -e "${BLUE}=== Build Summary ===${NC}"
echo -e "${GREEN}Hardware acceleration enabled:${NC}"
echo -e "${GREEN}  - Android: MediaCodec (H.264, H.265, MPEG-2, MPEG-4, VP8, VP9, AV1)${NC}"
echo -e "${GREEN}  - iOS: VideoToolbox (H.264, H.265, MPEG-2, MPEG-4, VP8, VP9, AV1)${NC}"
echo -e "${GREEN}  - macOS: VideoToolbox (H.264, H.265, MPEG-2, MPEG-4, VP8, VP9, AV1)${NC}" 