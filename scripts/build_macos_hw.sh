#!/bin/bash

# FFmpeg Kit macOS Build Script with Hardware Acceleration (VideoToolbox)
# This script builds FFmpeg Kit for macOS with VideoToolbox support

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== FFmpeg Kit macOS Build with Hardware Acceleration ===${NC}"

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
FFMPEG_VERSION="6.0.2"
FFMPEG_KIT_VERSION="6.0.2"
BUILD_DIR="build_macos_hw"
OUTPUT_DIR="output_macos_hw"

# Create build directories
mkdir -p $BUILD_DIR
mkdir -p $OUTPUT_DIR

echo -e "${YELLOW}Building FFmpeg Kit for macOS with VideoToolbox support...${NC}"

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
cat > macos_hw.sh << 'EOF'
#!/bin/bash

# Custom macOS build script with VideoToolbox support
./macos.sh \
  --enable-gpl \
  --enable-version3 \
  --enable-nonfree \
  --enable-videotoolbox \
  --enable-videotoolbox-h264 \
  --enable-videotoolbox-hevc \
  --enable-videotoolbox-mpeg2 \
  --enable-videotoolbox-mpeg4 \
  --enable-videotoolbox-vp8 \
  --enable-videotoolbox-vp9 \
  --enable-videotoolbox-av1 \
  --enable-aom \
  --enable-chromaprint \
  --enable-fontconfig \
  --enable-freetype \
  --enable-fribidi \
  --enable-gmp \
  --enable-gnutls \
  --enable-kvazaar \
  --enable-lame \
  --enable-libaom \
  --enable-libass \
  --enable-libiconv \
  --enable-libilbc \
  --enable-libtheora \
  --enable-libvorbis \
  --enable-libvpx \
  --enable-libwebp \
  --enable-libxml2 \
  --enable-opencore-amr \
  --enable-opus \
  --enable-shine \
  --enable-snappy \
  --enable-soxr \
  --enable-speex \
  --enable-twolame \
  --enable-vo-amrwbenc \
  --enable-zimg \
  --enable-libx264 \
  --enable-libx265 \
  --enable-libxvid \
  --enable-vidstab
EOF

chmod +x macos_hw.sh

echo -e "${YELLOW}Starting macOS build with VideoToolbox support...${NC}"
./macos_hw.sh

# Copy built artifacts
echo -e "${YELLOW}Copying built artifacts...${NC}"
cp -r prebuilt/* ../$OUTPUT_DIR/

cd ..

echo -e "${GREEN}=== macOS build completed successfully! ===${NC}"
echo -e "${GREEN}Built artifacts are in: $OUTPUT_DIR${NC}"
echo -e "${GREEN}VideoToolbox support is enabled for:${NC}"
echo -e "${GREEN}  - H.264/AVC${NC}"
echo -e "${GREEN}  - H.265/HEVC${NC}"
echo -e "${GREEN}  - MPEG-2${NC}"
echo -e "${GREEN}  - MPEG-4${NC}"
echo -e "${GREEN}  - VP8${NC}"
echo -e "${GREEN}  - VP9${NC}"
echo -e "${GREEN}  - AV1${NC}" 