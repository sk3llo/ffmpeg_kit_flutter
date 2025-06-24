#!/bin/bash

# Download and unzip MacOS framework with VideoToolbox support
# Update the URL below with your hosted binary URL

# Configuration
VERSION="6.0.2"
MACOS_URL="https://github.com/Gperez88/ffmpeg_kit_flutter/releases/download/6.0.2/ffmpeg-kit-full-gpl-6.0.LTS-macos-framework.zip"

# Fallback to original URL if custom binary not available
FALLBACK_URL="https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/6.0.2/ffmpeg-kit-macos-full-gpl-6.0.zip"

echo "=== Downloading macOS framework with VideoToolbox support ==="

# Create Frameworks directory
mkdir -p Frameworks

# Try to download custom binary first
echo "Attempting to download custom binary with VideoToolbox support..."
if curl -L -f "$MACOS_URL" -o frameworks.tar.gz; then
    echo "✅ Successfully downloaded custom binary with VideoToolbox support"
    echo "📁 File: frameworks.tar.gz"
    echo "🔧 Hardware acceleration: VideoToolbox enabled"
    
    # Extract custom binary
    tar -xzf frameworks.tar.gz -C Frameworks
    rm frameworks.tar.gz
    
    echo "📦 Extracted frameworks to Frameworks/"
else
    echo "⚠️  Custom binary not available, downloading fallback binary..."
    if curl -L -f "$FALLBACK_URL" -o frameworks.zip; then
        echo "✅ Downloaded fallback binary (no VideoToolbox support)"
        echo "📁 File: frameworks.zip"
        echo "⚠️  Note: This binary does not include VideoToolbox support"
        echo "💡 To enable VideoToolbox, build custom binaries using: ./scripts/build_macos_hw.sh"
        
        # Extract fallback binary
        unzip -o frameworks.zip -d Frameworks
        rm frameworks.zip
    else
        echo "❌ Failed to download macOS binary"
        exit 1
    fi
fi

# Delete bitcode from all frameworks
echo "🧹 Removing bitcode from frameworks..."
if [ -d "Frameworks/ffmpeg-kit-macos-full-gpl" ]; then
    xcrun bitcode_strip -r Frameworks/ffmpeg-kit-macos-full-gpl/ffmpegkit.framework/ffmpegkit -o Frameworks/ffmpeg-kit-macos-full-gpl/ffmpegkit.framework/ffmpegkit
    xcrun bitcode_strip -r Frameworks/ffmpeg-kit-macos-full-gpl/libavcodec.framework/libavcodec -o Frameworks/ffmpeg-kit-macos-full-gpl/libavcodec.framework/libavcodec
    xcrun bitcode_strip -r Frameworks/ffmpeg-kit-macos-full-gpl/libavdevice.framework/libavdevice -o Frameworks/ffmpeg-kit-macos-full-gpl/libavdevice.framework/libavdevice
    xcrun bitcode_strip -r Frameworks/ffmpeg-kit-macos-full-gpl/libavfilter.framework/libavfilter -o Frameworks/ffmpeg-kit-macos-full-gpl/libavfilter.framework/libavfilter
    xcrun bitcode_strip -r Frameworks/ffmpeg-kit-macos-full-gpl/libavformat.framework/libavformat -o Frameworks/ffmpeg-kit-macos-full-gpl/libavformat.framework/libavformat
    xcrun bitcode_strip -r Frameworks/ffmpeg-kit-macos-full-gpl/libavutil.framework/libavutil -o Frameworks/ffmpeg-kit-macos-full-gpl/libavutil.framework/libavutil
    xcrun bitcode_strip -r Frameworks/ffmpeg-kit-macos-full-gpl/libswresample.framework/libswresample -o Frameworks/ffmpeg-kit-macos-full-gpl/libswresample.framework/libswresample
    xcrun bitcode_strip -r Frameworks/ffmpeg-kit-macos-full-gpl/libswscale.framework/libswscale -o Frameworks/ffmpeg-kit-macos-full-gpl/libswscale.framework/libswscale
    echo "✅ Bitcode removed from all frameworks"
else
    echo "⚠️  Framework directory structure not found, skipping bitcode removal"
fi

echo "=== macOS setup completed ==="