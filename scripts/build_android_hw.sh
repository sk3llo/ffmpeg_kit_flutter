#!/bin/bash

# FFmpeg Kit Android Build Script with Hardware Acceleration (MediaCodec)
# This script builds FFmpeg Kit for Android with MediaCodec support

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== FFmpeg Kit Android Build with Hardware Acceleration ===${NC}"

# Check if required environment variables are set
if [ -z "$ANDROID_SDK_ROOT" ]; then
    echo -e "${RED}Error: ANDROID_SDK_ROOT environment variable is not set${NC}"
    echo "Please set it to your Android SDK path"
    exit 1
fi

if [ -z "$ANDROID_NDK_ROOT" ]; then
    echo -e "${RED}Error: ANDROID_NDK_ROOT environment variable is not set${NC}"
    echo "Please set it to your Android NDK path"
    exit 1
fi

# Build configuration
FFMPEG_VERSION="6.0.2"
FFMPEG_KIT_VERSION="6.0.2"
BUILD_DIR="build_android_hw"
OUTPUT_DIR="output_android_hw"

# Create build directories
mkdir -p $BUILD_DIR
mkdir -p $OUTPUT_DIR

echo -e "${YELLOW}Building FFmpeg Kit for Android with MediaCodec support...${NC}"

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
cat > android_hw.sh << 'EOF'
#!/bin/bash

# Custom Android build script with MediaCodec support
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT}"
export ANDROID_NDK_ROOT="${ANDROID_NDK_ROOT}"

# Build with hardware acceleration enabled
./android.sh \
  --enable-gpl \
  --enable-version3 \
  --enable-nonfree \
  --enable-mediacodec \
  --enable-mediacodec-h264 \
  --enable-mediacodec-hevc \
  --enable-mediacodec-mpeg2 \
  --enable-mediacodec-mpeg4 \
  --enable-mediacodec-vp8 \
  --enable-mediacodec-vp9 \
  --enable-mediacodec-av1 \
  --enable-amf \
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

chmod +x android_hw.sh

echo -e "${YELLOW}Starting Android build with MediaCodec support...${NC}"
./android_hw.sh

# Copy built artifacts
echo -e "${YELLOW}Copying built artifacts...${NC}"
cp -r prebuilt/* ../$OUTPUT_DIR/

cd ..

echo -e "${GREEN}=== Android build completed successfully! ===${NC}"
echo -e "${GREEN}Built artifacts are in: $OUTPUT_DIR${NC}"
echo -e "${GREEN}MediaCodec support is enabled for:${NC}"
echo -e "${GREEN}  - H.264/AVC${NC}"
echo -e "${GREEN}  - H.265/HEVC${NC}"
echo -e "${GREEN}  - MPEG-2${NC}"
echo -e "${GREEN}  - MPEG-4${NC}"
echo -e "${GREEN}  - VP8${NC}"
echo -e "${GREEN}  - VP9${NC}"
echo -e "${GREEN}  - AV1${NC}" 