#!/bin/bash

# Download and unzip iOS framework with VideoToolbox support
# Update the URL below with your hosted binary URL

# Configuration
VERSION="6.0.2"
IOS_URL="https://github.com/Gperez88/ffmpeg_kit_flutter/releases/download/6.0.2/ffmpeg-kit-full-gpl-6.0.LTS-ios-framework.zip"

# Fallback to original URL if custom binary not available
FALLBACK_URL="https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/6.0.2/ffmpeg-kit-full-gpl-6.0.LTS-ios-framework.zip"

echo "=== Downloading iOS framework with VideoToolbox support ==="

# Create Frameworks directory
mkdir -p Frameworks

# Try to download custom binary first
echo "Attempting to download custom binary with VideoToolbox support..."
if curl -L -f "$IOS_URL" -o frameworks.tar.gz; then
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
        echo "💡 To enable VideoToolbox, build custom binaries using: ./scripts/build_ios_hw.sh"
        
        # Extract fallback binary
        unzip -o frameworks.zip -d Frameworks
        rm frameworks.zip
    else
        echo "❌ Failed to download iOS binary"
        exit 1
    fi
fi

# Delete bitcode from all frameworks (required for App Store)
echo "🧹 Removing bitcode from frameworks..."
if [ -d "Frameworks/ffmpegkit.framework" ]; then
    xcrun bitcode_strip -r Frameworks/ffmpegkit.framework/ffmpegkit -o Frameworks/ffmpegkit.framework/ffmpegkit
    xcrun bitcode_strip -r Frameworks/libavcodec.framework/libavcodec -o Frameworks/libavcodec.framework/libavcodec
    xcrun bitcode_strip -r Frameworks/libavdevice.framework/libavdevice -o Frameworks/libavdevice.framework/libavdevice
    xcrun bitcode_strip -r Frameworks/libavfilter.framework/libavfilter -o Frameworks/libavfilter.framework/libavfilter
    xcrun bitcode_strip -r Frameworks/libavformat.framework/libavformat -o Frameworks/libavformat.framework/libavformat
    xcrun bitcode_strip -r Frameworks/libavutil.framework/libavutil -o Frameworks/libavutil.framework/libavutil
    xcrun bitcode_strip -r Frameworks/libswresample.framework/libswresample -o Frameworks/libswresample.framework/libswresample
    xcrun bitcode_strip -r Frameworks/libswscale.framework/libswscale -o Frameworks/libswscale.framework/libswscale
    echo "✅ Bitcode removed from all frameworks"
else
    echo "⚠️  Framework directory structure not found, skipping bitcode removal"
fi

echo "=== iOS setup completed ==="