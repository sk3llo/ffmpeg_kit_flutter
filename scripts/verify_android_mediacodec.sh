#!/bin/bash

# Script de verificación para MediaCodec en Android
# Autor: Assistant
# Fecha: $(date)

set -e

echo "🤖 **Verificación de MediaCodec en Android**"
echo "============================================"

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

echo ""
log_info "Verificando configuración de MediaCodec..."

# Verificar dispositivos Android conectados
echo ""
log_info "Verificando dispositivos Android..."

android_devices=$(adb devices | grep -c "device$" || echo "0")
if [ "$android_devices" -gt 0 ]; then
    log_success "Dispositivos Android conectados: $android_devices"
    
    # Obtener información del dispositivo
    device_id=$(adb devices | grep "device$" | head -1 | cut -f1)
    log_info "Dispositivo principal: $device_id"
    
    # Verificar versión de Android
    android_version=$(adb -s $device_id shell getprop ro.build.version.release)
    log_info "Versión de Android: $android_version"
    
    # Verificar arquitectura
    arch=$(adb -s $device_id shell getprop ro.product.cpu.abi)
    log_info "Arquitectura: $arch"
    
else
    log_error "No se detectaron dispositivos Android"
    exit 1
fi

# Verificar AAR de MediaCodec
echo ""
log_info "Verificando AAR de MediaCodec..."

if [ -f "libs/com.arthenica.ffmpegkit-flutter-7.0.aar" ]; then
    log_success "AAR encontrado"
    
    # Crear directorio temporal
    temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # Extraer AAR
    unzip -q /Users/gperez/Documents/projects/venqis/ffmpeg_kit_flutter/libs/com.arthenica.ffmpegkit-flutter-7.0.aar
    
    # Verificar MediaCodec en librerías nativas
    if [ -f "jni/arm64-v8a/libffmpegkit.so" ]; then
        log_success "Librerías nativas encontradas"
        
        # Verificar MediaCodec habilitado
        if strings jni/arm64-v8a/libffmpegkit.so | grep -q "enable-mediacodec"; then
            log_success "MediaCodec habilitado en librerías nativas"
        else
            log_error "MediaCodec NO habilitado en librerías nativas"
        fi
        
        # Verificar codecs MediaCodec
        codecs=("h264_mediacodec" "hevc_mediacodec" "mpeg4_mediacodec")
        for codec in "${codecs[@]}"; do
            if strings jni/arm64-v8a/libffmpegkit.so | grep -q "$codec"; then
                log_success "Codec $codec encontrado"
            else
                log_warning "Codec $codec NO encontrado"
            fi
        done
        
    else
        log_error "Librerías nativas no encontradas"
    fi
    
    cd - > /dev/null
    rm -rf "$temp_dir"
else
    log_error "AAR no encontrado"
fi

# Verificar configuración de build.gradle
echo ""
log_info "Verificando configuración de build.gradle..."

if [ -f "android/build.gradle" ]; then
    log_success "build.gradle encontrado"
    
    # Verificar MediaCodec en build.gradle
    if grep -q "mediacodec\|MediaCodec" android/build.gradle; then
        log_success "MediaCodec configurado en build.gradle"
    else
        log_warning "MediaCodec NO configurado en build.gradle"
    fi
    
    # Verificar minSdk
    min_sdk=$(grep -o "minSdk.*[0-9]*" android/build.gradle | grep -o "[0-9]*" | head -1)
    if [ "$min_sdk" -ge 21 ]; then
        log_success "minSdk $min_sdk (soporta MediaCodec)"
    else
        log_warning "minSdk $min_sdk (puede no soportar MediaCodec)"
    fi
else
    log_error "build.gradle no encontrado"
fi

# Verificar AndroidManifest.xml
echo ""
log_info "Verificando AndroidManifest.xml..."

if [ -f "android/src/main/AndroidManifest.xml" ]; then
    log_success "AndroidManifest.xml encontrado"
    
    # Verificar permisos de MediaCodec
    if grep -q "media_codec" android/src/main/AndroidManifest.xml; then
        log_success "Permisos de MediaCodec configurados"
    else
        log_warning "Permisos de MediaCodec NO configurados"
    fi
else
    log_error "AndroidManifest.xml no encontrado"
fi

# Verificar configuración Flutter
echo ""
log_info "Verificando configuración Flutter..."

if [ -f "example/pubspec.lock" ]; then
    log_success "Dependencias Flutter instaladas"
else
    log_warning "Dependencias Flutter no instaladas"
fi

echo ""
log_info "Resumen de verificación:"
echo "=========================="
echo "✅ Dispositivos Android conectados: $android_devices"
echo "✅ MediaCodec en AAR: $(strings libs/com.arthenica.ffmpegkit-flutter-7.0.aar | grep -c "enable-mediacodec" || echo "0")"
echo "✅ Codecs MediaCodec disponibles: $(strings libs/com.arthenica.ffmpegkit-flutter-7.0.aar | grep -c "mediacodec" || echo "0")"

echo ""
log_success "Verificación completada!"
echo ""
log_info "Para probar MediaCodec en Android:"
echo "1. Ejecuta: cd example && flutter run -d 'ID_DEL_DISPOSITIVO'"
echo "2. Presiona el botón 'Hardware' en la app"
echo "3. Presiona el botón 'MediaCodec' para verificar codecs"
echo "4. Presiona el botón 'List Codecs' para listar codecs MediaCodec"
echo "5. Compara el rendimiento con el botón 'Software'" 