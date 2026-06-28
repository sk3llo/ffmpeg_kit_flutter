#ifndef FLUTTER_PLUGIN_FFMPEG_KIT_FLUTTER_PLUGIN_H_
#define FLUTTER_PLUGIN_FFMPEG_KIT_FLUTTER_PLUGIN_H_

#include <flutter/encodable_value.h>
#include <flutter/event_channel.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <windows.h>
#include <memory>
#include <functional>
#include <string>
#include <vector>
#include <queue>
#include <mutex>
#include <cstdint>

namespace ffmpeg_kit_flutter {

typedef void (*FnVoid)();
typedef void (*FnVoidLong)(long);
typedef void (*FnVoidInt)(int);
typedef void (*FnVoidLongInt)(long, int);
typedef void (*FnVoidStr)(const char*);
typedef void (*FnVoidStrStr)(const char*, const char*);
typedef char* (*FnStrVoid)();
typedef char* (*FnStrLong)(long);
typedef char* (*FnStrLongInt)(long, int);
typedef char* (*FnStrInt)(int);
typedef char* (*FnStrStr)(const char*);
typedef char* (*FnStrPtrInt)(const char**, int);
typedef int (*FnIntVoid)();
typedef int (*FnIntLong)(long);
typedef int64_t (*FnInt64Long)(long);
typedef long (*FnLongLong)(long);
typedef void (*FnFreePtr)(void*);
typedef int (*FnIntStrStr)(const char*, const char*);

typedef void (*LogCallbackFn)(long, int, const char*);
typedef void (*StatisticsCallbackFn)(long, int, float, float, int64_t, double, double, double);
typedef void (*SessionCompleteCallbackFn)(long, int);

typedef void (*FnEnableLogCallback)(LogCallbackFn);
typedef void (*FnEnableStatisticsCallback)(StatisticsCallbackFn);
typedef void (*FnEnableSessionCompleteCallback)(SessionCompleteCallbackFn);

class FFmpegKitFlutterPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  FFmpegKitFlutterPlugin(flutter::PluginRegistrarWindows* registrar);
  virtual ~FFmpegKitFlutterPlugin();

  FFmpegKitFlutterPlugin(const FFmpegKitFlutterPlugin&) = delete;
  FFmpegKitFlutterPlugin& operator=(const FFmpegKitFlutterPlugin&) = delete;

  bool logs_enabled_ = false;
  bool statistics_enabled_ = false;
  std::mutex event_queue_mutex_;
  std::queue<flutter::EncodableValue> pending_events_;
  std::mutex task_queue_mutex_;
  std::queue<std::function<void()>> pending_tasks_;

  void EnqueueEvent(flutter::EncodableValue event);
  void ProcessPendingEvents();

  // Posts a task to be run on the platform (UI) thread. Used to reply to
  // method calls from background worker threads, since flutter::MethodResult
  // must only be invoked on the platform thread.
  void PostToPlatformThread(std::function<void()> task);
  void ProcessPendingTasks();

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  bool LoadLibrary();
  void RegisterCallbacks();
  flutter::EncodableValue ParseJson(const char* json);
  flutter::EncodableValue ParseJsonArray(const char* json);
  flutter::EncodableList ParseSessionListJson(const char* json);
  flutter::EncodableList ParseLogListJson(const char* json);
  flutter::EncodableList ParseStatisticsListJson(const char* json);

  flutter::PluginRegistrarWindows* registrar_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> method_channel_;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>> event_channel_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> event_sink_owner_;
  HWND msg_hwnd_ = nullptr;

  HMODULE lib_ = nullptr;

  // Function pointers
  FnStrPtrInt fn_create_ffmpeg_session_ = nullptr;
  FnStrPtrInt fn_create_ffprobe_session_ = nullptr;
  FnStrPtrInt fn_create_media_info_session_ = nullptr;
  FnInt64Long fn_session_get_end_time_ = nullptr;
  FnLongLong fn_session_get_duration_ = nullptr;
  FnIntLong fn_session_get_state_ = nullptr;
  FnIntLong fn_session_get_return_code_ = nullptr;
  FnStrLong fn_session_get_fail_stack_trace_ = nullptr;
  FnIntLong fn_session_there_are_async_messages_ = nullptr;
  FnStrLong fn_session_get_command_ = nullptr;
  FnStrLongInt fn_session_get_all_logs_as_string_ = nullptr;
  FnStrLong fn_session_get_logs_json_ = nullptr;
  FnStrLongInt fn_session_get_all_logs_json_ = nullptr;
  FnStrLong fn_session_get_statistics_json_ = nullptr;
  FnStrLongInt fn_session_get_all_statistics_json_ = nullptr;
  FnVoidLong fn_ffmpeg_execute_ = nullptr;
  FnVoidLong fn_ffprobe_execute_ = nullptr;
  FnVoidLongInt fn_media_info_execute_ = nullptr;
  FnVoidLong fn_async_ffmpeg_execute_ = nullptr;
  FnVoidLong fn_async_ffprobe_execute_ = nullptr;
  FnVoidLongInt fn_async_media_info_execute_ = nullptr;
  FnVoid fn_cancel_ = nullptr;
  FnVoidLong fn_cancel_session_ = nullptr;
  FnVoid fn_enable_redirection_ = nullptr;
  FnVoid fn_disable_redirection_ = nullptr;
  FnIntVoid fn_get_log_level_ = nullptr;
  FnVoidInt fn_set_log_level_ = nullptr;
  FnStrVoid fn_get_ffmpeg_version_ = nullptr;
  FnIntVoid fn_is_lts_build_ = nullptr;
  FnStrVoid fn_get_build_date_ = nullptr;
  FnVoidStrStr fn_set_environment_variable_ = nullptr;
  FnVoidInt fn_ignore_signal_ = nullptr;
  FnIntVoid fn_get_session_history_size_ = nullptr;
  FnVoidInt fn_set_session_history_size_ = nullptr;
  FnStrVoid fn_register_new_pipe_ = nullptr;
  FnVoidStr fn_close_pipe_ = nullptr;
  FnVoidStr fn_set_fontconfig_path_ = nullptr;
  FnVoidStrStr fn_set_font_directory_ = nullptr;
  FnVoidStrStr fn_set_font_directory_list_ = nullptr;
  FnIntVoid fn_get_log_redirection_strategy_ = nullptr;
  FnVoidInt fn_set_log_redirection_strategy_ = nullptr;
  FnIntLong fn_messages_in_transmit_ = nullptr;
  FnStrVoid fn_get_platform_ = nullptr;
  FnIntStrStr fn_write_to_pipe_ = nullptr;
  FnStrLong fn_get_session_json_ = nullptr;
  FnStrVoid fn_get_last_session_json_ = nullptr;
  FnStrVoid fn_get_last_completed_session_json_ = nullptr;
  FnStrVoid fn_get_sessions_json_ = nullptr;
  FnVoid fn_clear_sessions_ = nullptr;
  FnStrInt fn_get_sessions_by_state_json_ = nullptr;
  FnStrVoid fn_get_ffmpeg_sessions_json_ = nullptr;
  FnStrVoid fn_get_ffprobe_sessions_json_ = nullptr;
  FnStrVoid fn_get_media_info_sessions_json_ = nullptr;
  FnStrLong fn_get_media_information_json_ = nullptr;
  FnStrStr fn_mi_parser_from_ = nullptr;
  FnStrStr fn_mi_parser_from_with_error_ = nullptr;
  FnStrVoid fn_get_package_name_ = nullptr;
  FnStrVoid fn_get_external_libraries_json_ = nullptr;
  FnStrVoid fn_get_arch_ = nullptr;
  FnEnableLogCallback fn_enable_log_callback_ = nullptr;
  FnEnableStatisticsCallback fn_enable_statistics_callback_ = nullptr;
  FnEnableSessionCompleteCallback fn_enable_ffmpeg_complete_callback_ = nullptr;
  FnEnableSessionCompleteCallback fn_enable_ffprobe_complete_callback_ = nullptr;
  FnEnableSessionCompleteCallback fn_enable_media_info_complete_callback_ = nullptr;
  FnFreePtr fn_free_ = nullptr;
};

}  // namespace ffmpeg_kit_flutter

#endif  // FLUTTER_PLUGIN_FFMPEG_KIT_FLUTTER_PLUGIN_H_
