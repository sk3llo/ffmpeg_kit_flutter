#!/bin/bash

# Script de verificación final para VideoToolbox
# Autor: Assistant
# Fecha: $(date)

set -e

echo "🎯 **Verificación Final de VideoToolbox**"
echo "=========================================="

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
log_info "Verificando configuración de VideoToolbox..."

# Verificar frameworks del plugin principal
if [ -d "ios/Frameworks/ffmpegkit.framework" ]; then
    log_success "Framework ffmpegkit encontrado en plugin principal"
    
    # Verificar VideoToolbox en ffmpegkit
    if strings ios/Frameworks/ffmpegkit.framework/ffmpegkit | grep -q "enable-videotoolbox"; then
        log_success "VideoToolbox habilitado en ffmpegkit"
    else
        log_error "VideoToolbox NO habilitado en ffmpegkit"
    fi
    
    # Verificar VideoToolbox en libavcodec
    if strings ios/Frameworks/libavcodec.framework/libavcodec | grep -q "enable-videotoolbox"; then
        log_success "VideoToolbox habilitado en libavcodec"
    else
        log_error "VideoToolbox NO habilitado en libavcodec"
    fi
    
    # Verificar codecs VideoToolbox
    codecs=("h264_videotoolbox" "hevc_videotoolbox" "mpeg4_videotoolbox")
    for codec in "${codecs[@]}"; do
        if strings ios/Frameworks/libavcodec.framework/libavcodec | grep -q "$codec"; then
            log_success "Codec $codec encontrado"
        else
            log_warning "Codec $codec NO encontrado"
        fi
    done
else
    log_error "Frameworks no encontrados en plugin principal"
fi

# Verificar frameworks del ejemplo
echo ""
log_info "Verificando frameworks del ejemplo..."

if [ -d "example/ios/Frameworks/ffmpegkit.framework" ]; then
    log_success "Framework ffmpegkit encontrado en ejemplo"
    
    # Verificar VideoToolbox en ffmpegkit del ejemplo
    if strings example/ios/Frameworks/ffmpegkit.framework/ffmpegkit | grep -q "enable-videotoolbox"; then
        log_success "VideoToolbox habilitado en ffmpegkit del ejemplo"
    else
        log_error "VideoToolbox NO habilitado en ffmpegkit del ejemplo"
    fi
else
    log_error "Frameworks no encontrados en ejemplo"
fi

# Verificar configuración de pods
echo ""
log_info "Verificando configuración de pods..."

if [ -f "example/ios/Podfile.lock" ]; then
    log_success "Pods instalados"
    
    # Verificar que se está usando el subspec correcto
    if grep -q "full-gpl-lts" example/ios/Podfile.lock; then
        log_success "Subspec full-gpl-lts detectado"
    else
        log_warning "Subspec full-gpl-lts NO detectado"
    fi
else
    log_error "Pods no instalados"
fi

# Verificar dispositivos
echo ""
log_info "Verificando dispositivos conectados..."

ios_devices=$(xcrun devicectl list devices 2>/dev/null | grep -c "iPhone\|iPad" || echo "0")
if [ "$ios_devices" -gt 0 ]; then
    log_success "Dispositivos iOS conectados: $ios_devices"
else
    log_warning "No se detectaron dispositivos iOS"
fi

echo ""
log_info "Resumen de verificación:"
echo "=========================="
echo "✅ VideoToolbox en plugin principal: $(strings ios/Frameworks/ffmpegkit.framework/ffmpegkit | grep -c "enable-videotoolbox" || echo "0")"
echo "✅ VideoToolbox en ejemplo: $(strings example/ios/Frameworks/ffmpegkit.framework/ffmpegkit | grep -c "enable-videotoolbox" || echo "0")"
echo "✅ Codecs VideoToolbox disponibles: $(strings ios/Frameworks/libavcodec.framework/libavcodec | grep -c "videotoolbox" || echo "0")"
echo "✅ Dispositivos iOS conectados: $ios_devices"

echo ""
log_success "Verificación completada!"
echo ""
log_info "Para probar VideoToolbox en el iPhone:"
echo "1. Ejecuta: cd example && flutter run -d 'ID_DEL_IPHONE'"
echo "2. Presiona el botón 'VideoToolbox' en la app"
echo "3. Verifica que no aparezca 'Unknown encoder h264_videotoolbox'"
echo "4. Compara el rendimiento con el botón 'Software'" 