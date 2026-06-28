#include "include/ffmpeg_kit_flutter_new_https/f_fmpeg_kit_flutter_plugin.h"

#include <flutter/plugin_registrar_windows.h>

#include "ffmpeg_kit_flutter_plugin.h"

void FFmpegKitFlutterPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  ffmpeg_kit_flutter::FFmpegKitFlutterPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
