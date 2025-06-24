#!/bin/bash

# Download Android AAR with MediaCodec support
# Update the URL below with your hosted binary URL

# Configuration
VERSION="7.0"
ANDROID_URL="https://github.com/Gperez88/ffmpeg_kit_flutter/releases/download/7.0/com.arthenica.ffmpegkit-flutter-7.0.aar"

# Fallback to original URL if custom binary not available
FALLBACK_URL="https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/7.0/ffmpeg-kit-full-gpl-7.0.aar"

echo "=== Downloading Android AAR with MediaCodec support ==="

# Create libs directory
mkdir -p libs

# Try to download custom binary first
echo "Attempting to download custom binary with MediaCodec support..."
if curl -L -f "$ANDROID_URL" -o "libs/com.arthenica.ffmpegkit-flutter-$VERSION.aar"; then
    echo "✅ Successfully downloaded custom binary with MediaCodec support"
    echo "📁 File: libs/com.arthenica.ffmpegkit-flutter-$VERSION.aar"
    echo "🔧 Hardware acceleration: MediaCodec enabled"
else
    echo "⚠️  Custom binary not available, downloading fallback binary..."
    if curl -L -f "$FALLBACK_URL" -o "libs/com.arthenica.ffmpegkit-flutter-7.0.aar"; then
        echo "✅ Downloaded fallback binary (no MediaCodec support)"
        echo "📁 File: libs/com.arthenica.ffmpegkit-flutter-7.0.aar"
        echo "⚠️  Note: This binary does not include MediaCodec support"
        echo "💡 To enable MediaCodec, build custom binaries using: ./scripts/build_android_hw.sh"
    else
        echo "❌ Failed to download Android binary"
        exit 1
    fi
fi

echo "=== Android setup completed ==="