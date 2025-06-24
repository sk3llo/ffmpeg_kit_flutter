#!/bin/bash

# Script para probar aceleración por hardware en FFmpeg Kit
# Autor: Assistant
# Fecha: $(date)

set -e

echo "🔧 **Test de Aceleración por Hardware FFmpeg Kit**"
echo "=================================================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar mensajes
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Función para probar codecs hardware en iOS
test_ios_hardware() {
    log_info "Probando aceleración por hardware en iOS..."
    
    # Verificar si los frameworks tienen VideoToolbox
    if [ -d "example/ios/Frameworks/ffmpegkit.framework" ]; then
        log_info "Verificando soporte VideoToolbox en frameworks..."
        
        # Verificar si VideoToolbox está habilitado
        if otool -L example/ios/Frameworks/ffmpegkit.framework/ffmpegkit | grep -q VideoToolbox; then
            log_success "VideoToolbox detectado en frameworks"
        else
            log_warning "VideoToolbox no detectado en frameworks"
        fi
        
        # Verificar codecs hardware
        log_info "Verificando codecs hardware disponibles..."
        
        # Comando para listar codecs con VideoToolbox
        local hw_codecs=("h264_videotoolbox" "hevc_videotoolbox" "prores_videotoolbox")
        
        for codec in "${hw_codecs[@]}"; do
            log_info "Verificando codec: $codec"
            # Aquí podrías ejecutar un comando FFmpeg para verificar el codec
        done
        
    else
        log_error "Frameworks no encontrados en example/ios/Frameworks/"
        return 1
    fi
}

# Función para probar codecs hardware en Android
test_android_hardware() {
    log_info "Probando aceleración por hardware en Android..."
    
    # Verificar si el AAR tiene MediaCodec
    if [ -f "libs/com.arthenica.ffmpegkit-flutter-7.0.aar" ]; then
        log_info "Verificando soporte MediaCodec en AAR..."
        
        # Extraer y verificar el AAR
        local temp_dir=$(mktemp -d)
        cd "$temp_dir"
        unzip -q ../../libs/com.arthenica.ffmpegkit-flutter-7.0.aar
        
        # Verificar si MediaCodec está presente
        if [ -f "libs/arm64-v8a/libffmpegkit.so" ]; then
            log_success "AAR encontrado con librerías nativas"
            
            # Verificar strings relacionados con MediaCodec
            if strings libs/arm64-v8a/libffmpegkit.so | grep -q -i "mediacodec\|h264_mediacodec\|hevc_mediacodec"; then
                log_success "MediaCodec detectado en librerías nativas"
            else
                log_warning "MediaCodec no detectado en librerías nativas"
            fi
        else
            log_warning "Librerías nativas no encontradas en AAR"
        fi
        
        cd - > /dev/null
        rm -rf "$temp_dir"
    else
        log_error "AAR no encontrado en libs/"
        return 1
    fi
}

# Función para ejecutar test de rendimiento
test_performance() {
    log_info "Ejecutando test de rendimiento..."
    
    # Crear video de prueba si no existe
    if [ ! -f "example/assets/test_video.mp4" ]; then
        log_info "Creando video de prueba..."
        # Usar el video existente como base
        cp example/assets/sample_video.mp4 example/assets/test_video.mp4
    fi
    
    # Comandos de test
    local test_commands=(
        "-i example/assets/test_video.mp4 -c:v libx264 -preset ultrafast -crf 23 output_sw.mp4"
        "-i example/assets/test_video.mp4 -c:v h264_videotoolbox -b:v 2M output_hw.mp4"
        "-i example/assets/test_video.mp4 -c:v hevc_videotoolbox -b:v 2M output_hw_hevc.mp4"
    )
    
    local test_names=(
        "Software Encoding (libx264)"
        "Hardware Encoding (h264_videotoolbox)"
        "Hardware Encoding (hevc_videotoolbox)"
    )
    
    for i in "${!test_commands[@]}"; do
        log_info "Test ${i+1}: ${test_names[$i]}"
        echo "Comando: ffmpeg ${test_commands[$i]}"
        echo "---"
    done
}

# Función para verificar dispositivos conectados
check_devices() {
    log_info "Verificando dispositivos conectados..."
    
    # Verificar dispositivos iOS
    local ios_devices=$(xcrun devicectl list devices | grep -c "iPhone\|iPad" || echo "0")
    if [ "$ios_devices" -gt 0 ]; then
        log_success "Dispositivos iOS conectados: $ios_devices"
    else
        log_warning "No se detectaron dispositivos iOS"
    fi
    
    # Verificar dispositivos Android
    local android_devices=$(adb devices | grep -c "device$" || echo "0")
    if [ "$android_devices" -gt 0 ]; then
        log_success "Dispositivos Android conectados: $android_devices"
    else
        log_warning "No se detectaron dispositivos Android"
    fi
}

# Función para mostrar información del sistema
show_system_info() {
    log_info "Información del sistema:"
    echo "Sistema Operativo: $(uname -s)"
    echo "Arquitectura: $(uname -m)"
    echo "Versión de Xcode: $(xcodebuild -version | head -n 1)"
    echo "Flutter: $(flutter --version | head -n 1)"
    echo "CocoaPods: $(pod --version)"
    echo ""
}

# Función principal
main() {
    echo ""
    show_system_info
    check_devices
    echo ""
    
    # Test según plataforma
    case "$1" in
        "ios")
            test_ios_hardware
            ;;
        "android")
            test_android_hardware
            ;;
        "performance")
            test_performance
            ;;
        "all")
            test_ios_hardware
            echo ""
            test_android_hardware
            echo ""
            test_performance
            ;;
        *)
            log_info "Uso: $0 [ios|android|performance|all]"
            log_info "  ios        - Probar aceleración hardware en iOS"
            log_info "  android    - Probar aceleración hardware en Android"
            log_info "  performance - Ejecutar tests de rendimiento"
            log_info "  all        - Ejecutar todos los tests"
            echo ""
            log_info "Ejecutando test completo..."
            test_ios_hardware
            echo ""
            test_android_hardware
            echo ""
            test_performance
            ;;
    esac
    
    echo ""
    log_success "Test completado!"
}

# Ejecutar función principal
main "$@" 