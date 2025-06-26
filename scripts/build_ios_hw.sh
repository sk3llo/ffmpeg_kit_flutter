#!/bin/bash

# FFmpeg Kit iOS Build Script with Hardware Acceleration (VideoToolbox)
# This script builds FFmpeg Kit for iOS with VideoToolbox support

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== FFmpeg Kit iOS Build with Hardware Acceleration ===${NC}"

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}Error: This script must be run on macOS${NC}"
    exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}Error: Xcode is not installed or not in PATH${NC}"
    exit 1
fi

# Build configuration
FFMPEG_KIT_VERSION="v6.0.LTS"
OUTPUT_DIR="output_ios_hw"

# Create build directories
mkdir -p $OUTPUT_DIR

echo -e "${YELLOW}Building FFmpeg Kit for iOS with VideoToolbox support...${NC}"

# Clone FFmpeg Kit if not exists
if [ ! -d "ffmpeg-kit" ]; then
    echo -e "${YELLOW}Cloning FFmpeg Kit repository...${NC}"
    git clone https://github.com/arthenica/ffmpeg-kit.git
    cd ffmpeg-kit
    git checkout $FFMPEG_KIT_VERSION
else
    cd ffmpeg-kit
    echo -e "${YELLOW}Using existing FFmpeg Kit repository${NC}"
fi

# Create custom build script with hardware acceleration
cat > ios_hw.sh << 'EOF'
#!/bin/bash

# Custom iOS build script with VideoToolbox support
./ios.sh \
  --enable-gpl \
  --enable-ios-videotoolbox \
  --enable-libwebp \
  --enable-x264 \
  --enable-x265
EOF

chmod +x ios_hw.sh

echo -e "${YELLOW}Starting iOS build with VideoToolbox support...${NC}"
./ios_hw.sh

# Copy built artifacts
echo -e "${YELLOW}Copying built artifacts...${NC}"
cp -r prebuilt/* ../$OUTPUT_DIR/

cd ..

echo -e "${GREEN}=== iOS build completed successfully! ===${NC}"
echo -e "${GREEN}Built artifacts are in: $OUTPUT_DIR${NC}"
echo -e "${GREEN}Enabled features:${NC}"
echo -e "${GREEN}  - VideoToolbox hardware acceleration${NC}"
echo -e "${GREEN}  - WebP support${NC}"
echo -e "${GREEN}  - H.264 encoding (x264)${NC}"
echo -e "${GREEN}  - H.265 encoding (x265)${NC}" 