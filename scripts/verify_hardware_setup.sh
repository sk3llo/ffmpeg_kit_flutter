#!/bin/bash

# Script de verificación rápida para Hardware Acceleration
# Autor: Assistant
# Fecha: $(date)

set -e

echo "🔍 **Verificación Rápida de Hardware Acceleration**"
echo "=================================================="

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# Verificar frameworks iOS
echo ""
log_info "Verificando frameworks iOS..."

if [ -d "example/ios/Frameworks/ffmpegkit.framework" ]; then
    log_success "Framework ffmpegkit encontrado"
    
    # Verificar VideoToolbox en libavcodec
    if otool -L example/ios/Frameworks/libavcodec.framework/libavcodec | grep -q VideoToolbox; then
        log_success "VideoToolbox detectado en libavcodec"
    else
        log_error "VideoToolbox NO detectado en libavcodec"
    fi
    
    # Verificar codecs VideoToolbox
    codecs=("h264_videotoolbox" "hevc_videotoolbox" "mpeg4_videotoolbox")
    for codec in "${codecs[@]}"; do
        if strings example/ios/Frameworks/libavcodec.framework/libavcodec | grep -q "$codec"; then
            log_success "Codec $codec encontrado"
        else
            log_warning "Codec $codec NO encontrado"
        fi
    done
else
    log_error "Frameworks iOS no encontrados"
fi

# Verificar AAR Android
echo ""
log_info "Verificando AAR Android..."

if [ -f "libs/com.arthenica.ffmpegkit-flutter-7.0.aar" ]; then
    log_success "AAR Android encontrado"
    
    # Verificar MediaCodec
    temp_dir=$(mktemp -d)
    cd "$temp_dir"
    unzip -q "$OLDPWD/libs/com.arthenica.ffmpegkit-flutter-7.0.aar"
    
    if [ -f "libs/arm64-v8a/libffmpegkit.so" ]; then
        log_success "Librerías nativas encontradas"
        
        if strings libs/arm64-v8a/libffmpegkit.so | grep -q -i "mediacodec"; then
            log_success "MediaCodec detectado"
        else
            log_warning "MediaCodec NO detectado"
        fi
    else
        log_warning "Librerías nativas no encontradas"
    fi
    
    cd - > /dev/null
    rm -rf "$temp_dir"
else
    log_error "AAR Android no encontrado"
fi

# Verificar dispositivos
echo ""
log_info "Verificando dispositivos conectados..."

# iOS
ios_devices=$(xcrun devicectl list devices 2>/dev/null | grep -c "iPhone\|iPad" || echo "0")
if [ "$ios_devices" -gt 0 ]; then
    log_success "Dispositivos iOS conectados: $ios_devices"
else
    log_warning "No se detectaron dispositivos iOS"
fi

# Android
android_devices=$(adb devices 2>/dev/null | grep -c "device$" || echo "0")
if [ "$android_devices" -gt 0 ]; then
    log_success "Dispositivos Android conectados: $android_devices"
else
    log_warning "No se detectaron dispositivos Android"
fi

# Verificar configuración Flutter
echo ""
log_info "Verificando configuración Flutter..."

if [ -f "example/ios/Podfile.lock" ]; then
    log_success "Pods instalados"
else
    log_warning "Pods no instalados"
fi

if [ -f "example/pubspec.lock" ]; then
    log_success "Dependencias Flutter instaladas"
else
    log_warning "Dependencias Flutter no instaladas"
fi

echo ""
log_info "Resumen de verificación:"
echo "=========================="
echo "✅ Frameworks iOS con VideoToolbox: $(otool -L example/ios/Frameworks/libavcodec.framework/libavcodec | grep -c VideoToolbox || echo "0")"
echo "✅ Codecs VideoToolbox disponibles: $(strings example/ios/Frameworks/libavcodec.framework/libavcodec | grep -c "videotoolbox" || echo "0")"
echo "✅ Dispositivos iOS conectados: $ios_devices"
echo "✅ Dispositivos Android conectados: $android_devices"

echo ""
log_success "Verificación completada!"
echo ""
log_info "Para probar en el iPhone:"
echo "1. Ejecuta: cd example && flutter run -d 'ID_DEL_IPHONE'"
echo "2. Presiona el botón 'VideoToolbox' en la app"
echo "3. Presiona el botón 'List Codecs' para verificar codecs disponibles" 