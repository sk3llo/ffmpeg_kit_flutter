#include "ffmpeg_kit_flutter_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter/event_stream_handler_functions.h>

#include <string>
#include <vector>
#include <thread>
#include <mutex>
#include <cctype>
#include <cstdio>

namespace ffmpeg_kit_flutter {

static FFmpegKitFlutterPlugin* g_plugin_instance = nullptr;
static std::mutex g_callback_mutex;

static constexpr UINT WM_FFMPEGKIT_EVENT = WM_APP + 0x4B49;
static constexpr UINT WM_FFMPEGKIT_TASK = WM_APP + 0x4B50;
static const wchar_t kMsgWindowClass[] = L"FFmpegKitFlutterEventWindow";

static LRESULT CALLBACK MsgWindowProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp) {
    if (msg == WM_FFMPEGKIT_EVENT || msg == WM_FFMPEGKIT_TASK) {
        auto* plugin = reinterpret_cast<FFmpegKitFlutterPlugin*>(
            GetWindowLongPtr(hwnd, GWLP_USERDATA));
        if (plugin) {
            if (msg == WM_FFMPEGKIT_EVENT) {
                plugin->ProcessPendingEvents();
            } else {
                plugin->ProcessPendingTasks();
            }
        }
        return 0;
    }
    return DefWindowProc(hwnd, msg, wp, lp);
}

static void CALLBACK StaticLogCallback(long session_id, int level, const char* message) {
    std::lock_guard<std::mutex> lock(g_callback_mutex);
    if (g_plugin_instance && g_plugin_instance->logs_enabled_) {
        flutter::EncodableMap log_map;
        log_map[flutter::EncodableValue("sessionId")] = flutter::EncodableValue(static_cast<int64_t>(session_id));
        log_map[flutter::EncodableValue("level")] = flutter::EncodableValue(level);
        log_map[flutter::EncodableValue("message")] = flutter::EncodableValue(std::string(message ? message : ""));

        flutter::EncodableMap event;
        event[flutter::EncodableValue("FFmpegKitLogCallbackEvent")] = flutter::EncodableValue(log_map);
        g_plugin_instance->EnqueueEvent(flutter::EncodableValue(event));
    }
}

static void CALLBACK StaticStatisticsCallback(long session_id, int video_frame_number,
    float video_fps, float video_quality, int64_t size,
    double time, double bitrate, double speed) {
    std::lock_guard<std::mutex> lock(g_callback_mutex);
    if (g_plugin_instance && g_plugin_instance->statistics_enabled_) {
        flutter::EncodableMap stat_map;
        stat_map[flutter::EncodableValue("sessionId")] = flutter::EncodableValue(static_cast<int64_t>(session_id));
        stat_map[flutter::EncodableValue("videoFrameNumber")] = flutter::EncodableValue(video_frame_number);
        stat_map[flutter::EncodableValue("videoFps")] = flutter::EncodableValue(static_cast<double>(video_fps));
        stat_map[flutter::EncodableValue("videoQuality")] = flutter::EncodableValue(static_cast<double>(video_quality));
        stat_map[flutter::EncodableValue("size")] = flutter::EncodableValue(size);
        stat_map[flutter::EncodableValue("time")] = flutter::EncodableValue(time);
        stat_map[flutter::EncodableValue("bitrate")] = flutter::EncodableValue(bitrate);
        stat_map[flutter::EncodableValue("speed")] = flutter::EncodableValue(speed);

        flutter::EncodableMap event;
        event[flutter::EncodableValue("FFmpegKitStatisticsCallbackEvent")] = flutter::EncodableValue(stat_map);
        g_plugin_instance->EnqueueEvent(flutter::EncodableValue(event));
    }
}

static void CALLBACK StaticSessionCompleteCallback(long session_id, int session_type) {
    std::lock_guard<std::mutex> lock(g_callback_mutex);
    if (g_plugin_instance) {
        flutter::EncodableMap session_map;
        session_map[flutter::EncodableValue("sessionId")] = flutter::EncodableValue(static_cast<int64_t>(session_id));
        session_map[flutter::EncodableValue("type")] = flutter::EncodableValue(session_type);

        flutter::EncodableMap event;
        event[flutter::EncodableValue("FFmpegKitCompleteCallbackEvent")] = flutter::EncodableValue(session_map);
        g_plugin_instance->EnqueueEvent(flutter::EncodableValue(event));
    }
}

void FFmpegKitFlutterPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
    auto plugin = std::make_unique<FFmpegKitFlutterPlugin>(registrar);
    g_plugin_instance = plugin.get();
    registrar->AddPlugin(std::move(plugin));
}

FFmpegKitFlutterPlugin::FFmpegKitFlutterPlugin(
    flutter::PluginRegistrarWindows* registrar)
    : registrar_(registrar) {

    WNDCLASSW wc = {};
    wc.lpfnWndProc = MsgWindowProc;
    wc.hInstance = GetModuleHandle(nullptr);
    wc.lpszClassName = kMsgWindowClass;
    RegisterClassW(&wc);
    msg_hwnd_ = CreateWindowW(kMsgWindowClass, L"", 0,
        0, 0, 0, 0, HWND_MESSAGE, nullptr, wc.hInstance, nullptr);
    if (msg_hwnd_) {
        SetWindowLongPtr(msg_hwnd_, GWLP_USERDATA,
            reinterpret_cast<LONG_PTR>(this));
    }

    method_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
        registrar->messenger(), "flutter.arthenica.com/ffmpeg_kit",
        &flutter::StandardMethodCodec::GetInstance());

    method_channel_->SetMethodCallHandler(
        [this](const auto& call, auto result) {
            HandleMethodCall(call, std::move(result));
        });

    auto handler = std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
        [this](const flutter::EncodableValue* arguments,
               std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events)
            -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
            event_sink_owner_ = std::move(events);
            RegisterCallbacks();
            return nullptr;
        },
        [this](const flutter::EncodableValue* arguments)
            -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
            event_sink_owner_.reset();
            return nullptr;
        });

    event_channel_ = std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
        registrar->messenger(), "flutter.arthenica.com/ffmpeg_kit_event",
        &flutter::StandardMethodCodec::GetInstance());
    event_channel_->SetStreamHandler(std::move(handler));

    LoadLibrary();
}

FFmpegKitFlutterPlugin::~FFmpegKitFlutterPlugin() {
    g_plugin_instance = nullptr;
    if (msg_hwnd_) {
        DestroyWindow(msg_hwnd_);
        msg_hwnd_ = nullptr;
    }
    UnregisterClassW(kMsgWindowClass, GetModuleHandle(nullptr));
    event_sink_owner_.reset();
    if (lib_) {
        FreeLibrary(lib_);
        lib_ = nullptr;
    }
}

void FFmpegKitFlutterPlugin::EnqueueEvent(flutter::EncodableValue event) {
    {
        std::lock_guard<std::mutex> lock(event_queue_mutex_);
        pending_events_.push(std::move(event));
    }
    if (msg_hwnd_) {
        PostMessage(msg_hwnd_, WM_FFMPEGKIT_EVENT, 0, 0);
    }
}

void FFmpegKitFlutterPlugin::ProcessPendingEvents() {
    std::lock_guard<std::mutex> lock(event_queue_mutex_);
    while (!pending_events_.empty()) {
        if (event_sink_owner_) {
            event_sink_owner_->Success(pending_events_.front());
        }
        pending_events_.pop();
    }
}

void FFmpegKitFlutterPlugin::PostToPlatformThread(std::function<void()> task) {
    {
        std::lock_guard<std::mutex> lock(task_queue_mutex_);
        pending_tasks_.push(std::move(task));
    }
    if (msg_hwnd_) {
        PostMessage(msg_hwnd_, WM_FFMPEGKIT_TASK, 0, 0);
    }
}

void FFmpegKitFlutterPlugin::ProcessPendingTasks() {
    // Drain into a local queue first so a task that itself posts another task
    // (or runs re-entrant Flutter code) does not deadlock on task_queue_mutex_.
    std::queue<std::function<void()>> tasks;
    {
        std::lock_guard<std::mutex> lock(task_queue_mutex_);
        std::swap(tasks, pending_tasks_);
    }
    while (!tasks.empty()) {
        tasks.front()();
        tasks.pop();
    }
}

bool FFmpegKitFlutterPlugin::LoadLibrary() {
    lib_ = ::LoadLibraryA("libffmpegkit.dll");
    if (!lib_) {
        OutputDebugStringA("FFmpegKitFlutterPlugin: Failed to load libffmpegkit.dll\n");
        return false;
    }

    #define LOAD_FN(name, type, symbol) name = (type)GetProcAddress(lib_, symbol)

    LOAD_FN(fn_create_ffmpeg_session_, FnStrPtrInt, "ffmpegkit_create_ffmpeg_session");
    LOAD_FN(fn_create_ffprobe_session_, FnStrPtrInt, "ffmpegkit_create_ffprobe_session");
    LOAD_FN(fn_create_media_info_session_, FnStrPtrInt, "ffmpegkit_create_media_information_session");
    LOAD_FN(fn_session_get_end_time_, FnInt64Long, "ffmpegkit_session_get_end_time");
    LOAD_FN(fn_session_get_duration_, FnLongLong, "ffmpegkit_session_get_duration");
    LOAD_FN(fn_session_get_state_, FnIntLong, "ffmpegkit_session_get_state");
    LOAD_FN(fn_session_get_return_code_, FnIntLong, "ffmpegkit_session_get_return_code");
    LOAD_FN(fn_session_get_fail_stack_trace_, FnStrLong, "ffmpegkit_session_get_fail_stack_trace");
    LOAD_FN(fn_session_there_are_async_messages_, FnIntLong, "ffmpegkit_session_there_are_async_messages");
    LOAD_FN(fn_session_get_command_, FnStrLong, "ffmpegkit_session_get_command");
    LOAD_FN(fn_session_get_all_logs_as_string_, FnStrLongInt, "ffmpegkit_session_get_all_logs_as_string");
    LOAD_FN(fn_session_get_logs_json_, FnStrLong, "ffmpegkit_session_get_logs_json");
    LOAD_FN(fn_session_get_all_logs_json_, FnStrLongInt, "ffmpegkit_session_get_all_logs_json");
    LOAD_FN(fn_session_get_statistics_json_, FnStrLong, "ffmpegkit_session_get_statistics_json");
    LOAD_FN(fn_session_get_all_statistics_json_, FnStrLongInt, "ffmpegkit_session_get_all_statistics_json");
    LOAD_FN(fn_ffmpeg_execute_, FnVoidLong, "ffmpegkit_ffmpeg_execute");
    LOAD_FN(fn_ffprobe_execute_, FnVoidLong, "ffmpegkit_ffprobe_execute");
    LOAD_FN(fn_media_info_execute_, FnVoidLongInt, "ffmpegkit_media_information_execute");
    LOAD_FN(fn_async_ffmpeg_execute_, FnVoidLong, "ffmpegkit_async_ffmpeg_execute");
    LOAD_FN(fn_async_ffprobe_execute_, FnVoidLong, "ffmpegkit_async_ffprobe_execute");
    LOAD_FN(fn_async_media_info_execute_, FnVoidLongInt, "ffmpegkit_async_media_information_execute");
    LOAD_FN(fn_cancel_, FnVoid, "ffmpegkit_cancel");
    LOAD_FN(fn_cancel_session_, FnVoidLong, "ffmpegkit_cancel_session");
    LOAD_FN(fn_enable_redirection_, FnVoid, "ffmpegkit_enable_redirection");
    LOAD_FN(fn_disable_redirection_, FnVoid, "ffmpegkit_disable_redirection");
    LOAD_FN(fn_get_log_level_, FnIntVoid, "ffmpegkit_get_log_level");
    LOAD_FN(fn_set_log_level_, FnVoidInt, "ffmpegkit_set_log_level");
    LOAD_FN(fn_get_ffmpeg_version_, FnStrVoid, "ffmpegkit_get_ffmpeg_version");
    LOAD_FN(fn_is_lts_build_, FnIntVoid, "ffmpegkit_is_lts_build");
    LOAD_FN(fn_get_build_date_, FnStrVoid, "ffmpegkit_get_build_date");
    LOAD_FN(fn_set_environment_variable_, FnVoidStrStr, "ffmpegkit_set_environment_variable");
    LOAD_FN(fn_ignore_signal_, FnVoidInt, "ffmpegkit_ignore_signal");
    LOAD_FN(fn_get_session_history_size_, FnIntVoid, "ffmpegkit_get_session_history_size");
    LOAD_FN(fn_set_session_history_size_, FnVoidInt, "ffmpegkit_set_session_history_size");
    LOAD_FN(fn_register_new_pipe_, FnStrVoid, "ffmpegkit_register_new_pipe");
    LOAD_FN(fn_close_pipe_, FnVoidStr, "ffmpegkit_close_pipe");
    LOAD_FN(fn_set_fontconfig_path_, FnVoidStr, "ffmpegkit_set_fontconfig_configuration_path");
    LOAD_FN(fn_set_font_directory_, FnVoidStrStr, "ffmpegkit_set_font_directory");
    LOAD_FN(fn_set_font_directory_list_, FnVoidStrStr, "ffmpegkit_set_font_directory_list");
    LOAD_FN(fn_get_log_redirection_strategy_, FnIntVoid, "ffmpegkit_get_log_redirection_strategy");
    LOAD_FN(fn_set_log_redirection_strategy_, FnVoidInt, "ffmpegkit_set_log_redirection_strategy");
    LOAD_FN(fn_messages_in_transmit_, FnIntLong, "ffmpegkit_messages_in_transmit");
    LOAD_FN(fn_get_platform_, FnStrVoid, "ffmpegkit_get_platform");
    LOAD_FN(fn_write_to_pipe_, FnIntStrStr, "ffmpegkit_write_to_pipe");
    LOAD_FN(fn_get_session_json_, FnStrLong, "ffmpegkit_get_session_json");
    LOAD_FN(fn_get_last_session_json_, FnStrVoid, "ffmpegkit_get_last_session_json");
    LOAD_FN(fn_get_last_completed_session_json_, FnStrVoid, "ffmpegkit_get_last_completed_session_json");
    LOAD_FN(fn_get_sessions_json_, FnStrVoid, "ffmpegkit_get_sessions_json");
    LOAD_FN(fn_clear_sessions_, FnVoid, "ffmpegkit_clear_sessions");
    LOAD_FN(fn_get_sessions_by_state_json_, FnStrInt, "ffmpegkit_get_sessions_by_state_json");
    LOAD_FN(fn_get_ffmpeg_sessions_json_, FnStrVoid, "ffmpegkit_get_ffmpeg_sessions_json");
    LOAD_FN(fn_get_ffprobe_sessions_json_, FnStrVoid, "ffmpegkit_get_ffprobe_sessions_json");
    LOAD_FN(fn_get_media_info_sessions_json_, FnStrVoid, "ffmpegkit_get_media_information_sessions_json");
    LOAD_FN(fn_get_media_information_json_, FnStrLong, "ffmpegkit_get_media_information_json");
    LOAD_FN(fn_mi_parser_from_, FnStrStr, "ffmpegkit_media_information_json_parser_from");
    LOAD_FN(fn_mi_parser_from_with_error_, FnStrStr, "ffmpegkit_media_information_json_parser_from_with_error");
    LOAD_FN(fn_get_package_name_, FnStrVoid, "ffmpegkit_get_package_name");
    LOAD_FN(fn_get_external_libraries_json_, FnStrVoid, "ffmpegkit_get_external_libraries_json");
    LOAD_FN(fn_get_arch_, FnStrVoid, "ffmpegkit_get_arch");
    LOAD_FN(fn_enable_log_callback_, FnEnableLogCallback, "ffmpegkit_enable_log_callback");
    LOAD_FN(fn_enable_statistics_callback_, FnEnableStatisticsCallback, "ffmpegkit_enable_statistics_callback");
    LOAD_FN(fn_enable_ffmpeg_complete_callback_, FnEnableSessionCompleteCallback, "ffmpegkit_enable_ffmpeg_session_complete_callback");
    LOAD_FN(fn_enable_ffprobe_complete_callback_, FnEnableSessionCompleteCallback, "ffmpegkit_enable_ffprobe_session_complete_callback");
    LOAD_FN(fn_enable_media_info_complete_callback_, FnEnableSessionCompleteCallback, "ffmpegkit_enable_media_information_session_complete_callback");
    LOAD_FN(fn_free_, FnFreePtr, "ffmpegkit_free");

    #undef LOAD_FN

    return true;
}

void FFmpegKitFlutterPlugin::RegisterCallbacks() {
    if (fn_enable_log_callback_) fn_enable_log_callback_(StaticLogCallback);
    if (fn_enable_statistics_callback_) fn_enable_statistics_callback_(StaticStatisticsCallback);
    if (fn_enable_ffmpeg_complete_callback_) fn_enable_ffmpeg_complete_callback_(StaticSessionCompleteCallback);
    if (fn_enable_ffprobe_complete_callback_) fn_enable_ffprobe_complete_callback_(StaticSessionCompleteCallback);
    if (fn_enable_media_info_complete_callback_) fn_enable_media_info_complete_callback_(StaticSessionCompleteCallback);
}

static void SkipWhitespace(const char*& p) {
    while (*p && std::isspace(static_cast<unsigned char>(*p))) ++p;
}

static std::string ParseJsonString(const char*& p) {
    std::string result;
    if (*p != '"') return result;
    ++p;
    while (*p && *p != '"') {
        if (*p == '\\') {
            ++p;
            switch (*p) {
                case '"': result += '"'; break;
                case '\\': result += '\\'; break;
                case '/': result += '/'; break;
                case 'b': result += '\b'; break;
                case 'f': result += '\f'; break;
                case 'n': result += '\n'; break;
                case 'r': result += '\r'; break;
                case 't': result += '\t'; break;
                default: result += *p; break;
            }
        } else {
            result += *p;
        }
        ++p;
    }
    if (*p == '"') ++p;
    return result;
}

static flutter::EncodableValue ParseJsonValue(const char*& p) {
    SkipWhitespace(p);
    if (!*p) return flutter::EncodableValue();

    if (*p == '"') {
        return flutter::EncodableValue(ParseJsonString(p));
    }
    if (*p == '{') {
        ++p;
        flutter::EncodableMap map;
        SkipWhitespace(p);
        while (*p && *p != '}') {
            SkipWhitespace(p);
            std::string key = ParseJsonString(p);
            SkipWhitespace(p);
            if (*p == ':') ++p;
            auto val = ParseJsonValue(p);
            map[flutter::EncodableValue(key)] = val;
            SkipWhitespace(p);
            if (*p == ',') ++p;
        }
        if (*p == '}') ++p;
        return flutter::EncodableValue(map);
    }
    if (*p == '[') {
        ++p;
        flutter::EncodableList list;
        SkipWhitespace(p);
        while (*p && *p != ']') {
            list.push_back(ParseJsonValue(p));
            SkipWhitespace(p);
            if (*p == ',') ++p;
        }
        if (*p == ']') ++p;
        return flutter::EncodableValue(list);
    }
    if (*p == 'n' && strncmp(p, "null", 4) == 0) {
        p += 4;
        return flutter::EncodableValue();
    }
    if (*p == 't' && strncmp(p, "true", 4) == 0) {
        p += 4;
        return flutter::EncodableValue(true);
    }
    if (*p == 'f' && strncmp(p, "false", 5) == 0) {
        p += 5;
        return flutter::EncodableValue(false);
    }
    // Number
    const char* start = p;
    bool is_double = false;
    if (*p == '-') ++p;
    while (std::isdigit(static_cast<unsigned char>(*p))) ++p;
    if (*p == '.') { is_double = true; ++p; while (std::isdigit(static_cast<unsigned char>(*p))) ++p; }
    if (*p == 'e' || *p == 'E') { is_double = true; ++p; if (*p == '+' || *p == '-') ++p; while (std::isdigit(static_cast<unsigned char>(*p))) ++p; }
    std::string num_str(start, p);
    if (num_str.empty()) return flutter::EncodableValue();
    try {
        if (is_double) {
            return flutter::EncodableValue(std::stod(num_str));
        }
        int64_t val = std::stoll(num_str);
        if (val >= INT32_MIN && val <= INT32_MAX) return flutter::EncodableValue(static_cast<int32_t>(val));
        return flutter::EncodableValue(val);
    } catch (...) {
        // Integers that overflow int64_t fall back to double; if even that
        // throws (out of range), return the raw text so we neither crash nor
        // silently drop the value.
        try {
            return flutter::EncodableValue(std::stod(num_str));
        } catch (...) {
            return flutter::EncodableValue(num_str);
        }
    }
}

flutter::EncodableValue FFmpegKitFlutterPlugin::ParseJson(const char* json) {
    if (!json) return flutter::EncodableValue();
    const char* p = json;
    return ParseJsonValue(p);
}

flutter::EncodableValue FFmpegKitFlutterPlugin::ParseJsonArray(const char* json) {
    if (!json) return flutter::EncodableValue(flutter::EncodableList());
    return ParseJson(json);
}

flutter::EncodableList FFmpegKitFlutterPlugin::ParseSessionListJson(const char* json) {
    auto val = ParseJsonArray(json);
    if (auto* list = std::get_if<flutter::EncodableList>(&val)) {
        return *list;
    }
    return flutter::EncodableList();
}

flutter::EncodableList FFmpegKitFlutterPlugin::ParseLogListJson(const char* json) {
    return ParseSessionListJson(json);
}

flutter::EncodableList FFmpegKitFlutterPlugin::ParseStatisticsListJson(const char* json) {
    return ParseSessionListJson(json);
}

static int64_t GetIntArg(const flutter::EncodableMap& args, const std::string& key, int64_t def = -1) {
    auto it = args.find(flutter::EncodableValue(key));
    if (it != args.end()) {
        if (auto* val = std::get_if<int32_t>(&it->second)) return *val;
        if (auto* val = std::get_if<int64_t>(&it->second)) return *val;
    }
    return def;
}

static std::string GetStringArg(const flutter::EncodableMap& args, const std::string& key) {
    auto it = args.find(flutter::EncodableValue(key));
    if (it != args.end()) {
        if (auto* val = std::get_if<std::string>(&it->second)) return *val;
    }
    return "";
}

static flutter::EncodableList GetListArg(const flutter::EncodableMap& args, const std::string& key) {
    auto it = args.find(flutter::EncodableValue(key));
    if (it != args.end()) {
        if (auto* val = std::get_if<flutter::EncodableList>(&it->second)) return *val;
    }
    return flutter::EncodableList();
}

static flutter::EncodableMap GetMapArg(const flutter::EncodableMap& args, const std::string& key) {
    auto it = args.find(flutter::EncodableValue(key));
    if (it != args.end()) {
        if (auto* val = std::get_if<flutter::EncodableMap>(&it->second)) return *val;
    }
    return flutter::EncodableMap();
}

static std::string JsonEscape(const std::string& s) {
    std::string out;
    out.reserve(s.size() + 2);
    for (char c : s) {
        switch (c) {
            case '"': out += "\\\""; break;
            case '\\': out += "\\\\"; break;
            case '\b': out += "\\b"; break;
            case '\f': out += "\\f"; break;
            case '\n': out += "\\n"; break;
            case '\r': out += "\\r"; break;
            case '\t': out += "\\t"; break;
            default:
                if (static_cast<unsigned char>(c) < 0x20) {
                    char buf[8];
                    snprintf(buf, sizeof(buf), "\\u%04x", static_cast<unsigned char>(c));
                    out += buf;
                } else {
                    out += c;
                }
        }
    }
    return out;
}

// Serializes an EncodableMap with string keys/values into a JSON object string,
// e.g. {"font.ttf":"My Font"}. Non-string entries are skipped.
static std::string EncodableMapToJsonObject(const flutter::EncodableMap& map) {
    std::string out = "{";
    bool first = true;
    for (const auto& kv : map) {
        const auto* key = std::get_if<std::string>(&kv.first);
        const auto* val = std::get_if<std::string>(&kv.second);
        if (!key || !val) continue;
        if (!first) out += ",";
        first = false;
        out += "\"" + JsonEscape(*key) + "\":\"" + JsonEscape(*val) + "\"";
    }
    out += "}";
    return out;
}

// Serializes an EncodableList of strings into a JSON array string,
// e.g. ["C:/fonts","D:/more"]. Non-string entries are skipped.
static std::string EncodableListToJsonArray(const flutter::EncodableList& list) {
    std::string out = "[";
    bool first = true;
    for (const auto& v : list) {
        const auto* s = std::get_if<std::string>(&v);
        if (!s) continue;
        if (!first) out += ",";
        first = false;
        out += "\"" + JsonEscape(*s) + "\"";
    }
    out += "]";
    return out;
}

void FFmpegKitFlutterPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {

    if (!lib_) {
        result->Error("LIBRARY_NOT_LOADED", "libffmpegkit.dll not loaded");
        return;
    }

    const auto& method = method_call.method_name();
    const auto* args_val = method_call.arguments();
    flutter::EncodableMap args;
    if (args_val && std::holds_alternative<flutter::EncodableMap>(*args_val)) {
        args = std::get<flutter::EncodableMap>(*args_val);
    }

    auto free_str = [this](char* s) {
        if (s && fn_free_) fn_free_(s);
    };

    // The dispatch below is wrapped so that an unexpected exception (e.g. a
    // bad_variant_access from a mistyped argument, or a std::sto* conversion)
    // is reported back to Dart as an error instead of crashing the host app.
    try {
    // Session creation
    if (method == "ffmpegSession" || method == "ffprobeSession" || method == "mediaInformationSession") {
        auto arg_list = GetListArg(args, "arguments");
        std::vector<std::string> str_args;
        std::vector<const char*> c_args;
        for (auto& a : arg_list) {
            if (auto* s = std::get_if<std::string>(&a)) {
                str_args.push_back(*s);
            }
        }
        for (auto& s : str_args) c_args.push_back(s.c_str());

        char* json = nullptr;
        if (method == "ffmpegSession" && fn_create_ffmpeg_session_) {
            json = fn_create_ffmpeg_session_(c_args.data(), (int)c_args.size());
        } else if (method == "ffprobeSession" && fn_create_ffprobe_session_) {
            json = fn_create_ffprobe_session_(c_args.data(), (int)c_args.size());
        } else if (fn_create_media_info_session_) {
            json = fn_create_media_info_session_(c_args.data(), (int)c_args.size());
        }
        if (json) {
            auto val = ParseJson(json);
            free_str(json);
            result->Success(val);
        } else {
            result->Success(flutter::EncodableValue());
        }
    }
    // Session queries
    else if (method == "abstractSessionGetEndTime") {
        long sid = (long)GetIntArg(args, "sessionId");
        if (fn_session_get_end_time_) {
            int64_t t = fn_session_get_end_time_(sid);
            if (t >= 0) result->Success(flutter::EncodableValue(t));
            else result->Success(flutter::EncodableValue());
        } else result->Success(flutter::EncodableValue());
    }
    else if (method == "abstractSessionGetDuration") {
        long sid = (long)GetIntArg(args, "sessionId");
        if (fn_session_get_duration_) {
            result->Success(flutter::EncodableValue(static_cast<int64_t>(fn_session_get_duration_(sid))));
        } else result->Success(flutter::EncodableValue(0));
    }
    else if (method == "abstractSessionGetAllLogs") {
        long sid = (long)GetIntArg(args, "sessionId");
        int timeout = (int)GetIntArg(args, "waitTimeout", -1);
        if (fn_session_get_all_logs_json_) {
            char* json = fn_session_get_all_logs_json_(sid, timeout);
            auto list = ParseLogListJson(json);
            free_str(json);
            result->Success(flutter::EncodableValue(list));
        } else result->Success(flutter::EncodableValue(flutter::EncodableList()));
    }
    else if (method == "abstractSessionGetLogs") {
        long sid = (long)GetIntArg(args, "sessionId");
        if (fn_session_get_logs_json_) {
            char* json = fn_session_get_logs_json_(sid);
            auto list = ParseLogListJson(json);
            free_str(json);
            result->Success(flutter::EncodableValue(list));
        } else result->Success(flutter::EncodableValue(flutter::EncodableList()));
    }
    else if (method == "abstractSessionGetAllLogsAsString") {
        long sid = (long)GetIntArg(args, "sessionId");
        int timeout = (int)GetIntArg(args, "waitTimeout", -1);
        if (fn_session_get_all_logs_as_string_) {
            char* s = fn_session_get_all_logs_as_string_(sid, timeout);
            if (s) {
                result->Success(flutter::EncodableValue(std::string(s)));
                free_str(s);
            } else result->Success(flutter::EncodableValue());
        } else result->Success(flutter::EncodableValue());
    }
    else if (method == "abstractSessionGetState") {
        long sid = (long)GetIntArg(args, "sessionId");
        if (fn_session_get_state_) {
            result->Success(flutter::EncodableValue(fn_session_get_state_(sid)));
        } else result->Success(flutter::EncodableValue());
    }
    else if (method == "abstractSessionGetReturnCode") {
        long sid = (long)GetIntArg(args, "sessionId");
        if (fn_session_get_return_code_) {
            int rc = fn_session_get_return_code_(sid);
            if (rc >= 0) result->Success(flutter::EncodableValue(rc));
            else result->Success(flutter::EncodableValue());
        } else result->Success(flutter::EncodableValue());
    }
    else if (method == "abstractSessionGetFailStackTrace") {
        long sid = (long)GetIntArg(args, "sessionId");
        if (fn_session_get_fail_stack_trace_) {
            char* s = fn_session_get_fail_stack_trace_(sid);
            if (s) {
                result->Success(flutter::EncodableValue(std::string(s)));
                free_str(s);
            } else result->Success(flutter::EncodableValue());
        } else result->Success(flutter::EncodableValue());
    }
    else if (method == "thereAreAsynchronousMessagesInTransmit") {
        long sid = (long)GetIntArg(args, "sessionId");
        if (fn_session_there_are_async_messages_) {
            result->Success(flutter::EncodableValue(fn_session_there_are_async_messages_(sid) != 0));
        } else result->Success(flutter::EncodableValue(false));
    }
    // ArchDetect
    else if (method == "getArch") {
        if (fn_get_arch_) {
            char* s = fn_get_arch_();
            if (s) {
                result->Success(flutter::EncodableValue(std::string(s)));
                free_str(s);
            } else result->Success(flutter::EncodableValue(""));
        } else result->Success(flutter::EncodableValue("x86_64"));
    }
    // FFmpegSession statistics
    else if (method == "ffmpegSessionGetAllStatistics") {
        long sid = (long)GetIntArg(args, "sessionId");
        int timeout = (int)GetIntArg(args, "waitTimeout", -1);
        if (fn_session_get_all_statistics_json_) {
            char* json = fn_session_get_all_statistics_json_(sid, timeout);
            auto list = ParseStatisticsListJson(json);
            free_str(json);
            result->Success(flutter::EncodableValue(list));
        } else result->Success(flutter::EncodableValue(flutter::EncodableList()));
    }
    else if (method == "ffmpegSessionGetStatistics") {
        long sid = (long)GetIntArg(args, "sessionId");
        if (fn_session_get_statistics_json_) {
            char* json = fn_session_get_statistics_json_(sid);
            auto list = ParseStatisticsListJson(json);
            free_str(json);
            result->Success(flutter::EncodableValue(list));
        } else result->Success(flutter::EncodableValue(flutter::EncodableList()));
    }
    // MediaInformation
    else if (method == "getMediaInformation" || method == "mediaInformationSessionGetMediaInformation") {
        long sid = (long)GetIntArg(args, "sessionId");
        if (fn_get_media_information_json_) {
            char* json = fn_get_media_information_json_(sid);
            if (json) {
                auto val = ParseJson(json);
                free_str(json);
                result->Success(val);
            } else result->Success(flutter::EncodableValue());
        } else result->Success(flutter::EncodableValue());
    }
    else if (method == "mediaInformationJsonParserFrom") {
        auto jsonOutput = GetStringArg(args, "ffprobeJsonOutput");
        if (fn_mi_parser_from_ && !jsonOutput.empty()) {
            char* json = fn_mi_parser_from_(jsonOutput.c_str());
            if (json) {
                auto val = ParseJson(json);
                free_str(json);
                result->Success(val);
            } else result->Success(flutter::EncodableValue());
        } else result->Success(flutter::EncodableValue());
    }
    else if (method == "mediaInformationJsonParserFromWithError") {
        auto jsonOutput = GetStringArg(args, "ffprobeJsonOutput");
        if (fn_mi_parser_from_with_error_ && !jsonOutput.empty()) {
            char* json = fn_mi_parser_from_with_error_(jsonOutput.c_str());
            if (json) {
                auto val = ParseJson(json);
                free_str(json);
                result->Success(val);
            } else {
                result->Error("PARSE_FAILED", "Parsing MediaInformation failed");
            }
        } else result->Error("INVALID_FFPROBE_JSON_OUTPUT", "Invalid ffprobe json output");
    }
    // Execution
    else if (method == "ffmpegSessionExecute") {
        long sid = (long)GetIntArg(args, "sessionId");
        if (fn_ffmpeg_execute_) {
            auto shared_result = std::shared_ptr<flutter::MethodResult<flutter::EncodableValue>>(std::move(result));
            std::thread([this, sid, shared_result]() {
                fn_ffmpeg_execute_(sid);
                PostToPlatformThread([shared_result]() {
                    shared_result->Success(flutter::EncodableValue());
                });
            }).detach();
            return;
        }
        result->Success(flutter::EncodableValue());
    }
    else if (method == "ffprobeSessionExecute") {
        long sid = (long)GetIntArg(args, "sessionId");
        if (fn_ffprobe_execute_) {
            auto shared_result = std::shared_ptr<flutter::MethodResult<flutter::EncodableValue>>(std::move(result));
            std::thread([this, sid, shared_result]() {
                fn_ffprobe_execute_(sid);
                PostToPlatformThread([shared_result]() {
                    shared_result->Success(flutter::EncodableValue());
                });
            }).detach();
            return;
        }
        result->Success(flutter::EncodableValue());
    }
    else if (method == "mediaInformationSessionExecute") {
        long sid = (long)GetIntArg(args, "sessionId");
        int timeout = (int)GetIntArg(args, "waitTimeout", 5000);
        if (fn_media_info_execute_) {
            auto shared_result = std::shared_ptr<flutter::MethodResult<flutter::EncodableValue>>(std::move(result));
            std::thread([this, sid, timeout, shared_result]() {
                fn_media_info_execute_(sid, timeout);
                PostToPlatformThread([shared_result]() {
                    shared_result->Success(flutter::EncodableValue());
                });
            }).detach();
            return;
        }
        result->Success(flutter::EncodableValue());
    }
    else if (method == "asyncFFmpegSessionExecute") {
        long sid = (long)GetIntArg(args, "sessionId");
        if (fn_async_ffmpeg_execute_) fn_async_ffmpeg_execute_(sid);
        result->Success(flutter::EncodableValue());
    }
    else if (method == "asyncFFprobeSessionExecute") {
        long sid = (long)GetIntArg(args, "sessionId");
        if (fn_async_ffprobe_execute_) fn_async_ffprobe_execute_(sid);
        result->Success(flutter::EncodableValue());
    }
    else if (method == "asyncMediaInformationSessionExecute") {
        long sid = (long)GetIntArg(args, "sessionId");
        int timeout = (int)GetIntArg(args, "waitTimeout", 5000);
        if (fn_async_media_info_execute_) fn_async_media_info_execute_(sid, timeout);
        result->Success(flutter::EncodableValue());
    }
    // Config
    else if (method == "enableRedirection") {
        logs_enabled_ = true;
        statistics_enabled_ = true;
        if (fn_enable_redirection_) fn_enable_redirection_();
        result->Success(flutter::EncodableValue());
    }
    else if (method == "disableRedirection") {
        if (fn_disable_redirection_) fn_disable_redirection_();
        result->Success(flutter::EncodableValue());
    }
    else if (method == "enableLogs") {
        logs_enabled_ = true;
        result->Success(flutter::EncodableValue());
    }
    else if (method == "disableLogs") {
        logs_enabled_ = false;
        result->Success(flutter::EncodableValue());
    }
    else if (method == "enableStatistics") {
        statistics_enabled_ = true;
        result->Success(flutter::EncodableValue());
    }
    else if (method == "disableStatistics") {
        statistics_enabled_ = false;
        result->Success(flutter::EncodableValue());
    }
    else if (method == "getLogLevel") {
        if (fn_get_log_level_) {
            result->Success(flutter::EncodableValue(fn_get_log_level_()));
        } else result->Success(flutter::EncodableValue(32));
    }
    else if (method == "setLogLevel") {
        int level = (int)GetIntArg(args, "level", 32);
        if (fn_set_log_level_) fn_set_log_level_(level);
        result->Success(flutter::EncodableValue());
    }
    else if (method == "getFFmpegVersion") {
        if (fn_get_ffmpeg_version_) {
            char* s = fn_get_ffmpeg_version_();
            result->Success(flutter::EncodableValue(std::string(s ? s : "")));
            free_str(s);
        } else result->Success(flutter::EncodableValue(""));
    }
    else if (method == "isLTSBuild") {
        if (fn_is_lts_build_) {
            result->Success(flutter::EncodableValue(fn_is_lts_build_() != 0));
        } else result->Success(flutter::EncodableValue(false));
    }
    else if (method == "getBuildDate") {
        if (fn_get_build_date_) {
            char* s = fn_get_build_date_();
            result->Success(flutter::EncodableValue(std::string(s ? s : "")));
            free_str(s);
        } else result->Success(flutter::EncodableValue(""));
    }
    else if (method == "setEnvironmentVariable") {
        auto name = GetStringArg(args, "variableName");
        auto value = GetStringArg(args, "variableValue");
        if (fn_set_environment_variable_ && !name.empty()) {
            fn_set_environment_variable_(name.c_str(), value.c_str());
        }
        result->Success(flutter::EncodableValue());
    }
    else if (method == "ignoreSignal") {
        int signal = (int)GetIntArg(args, "signal", -1);
        if (fn_ignore_signal_ && signal >= 0) fn_ignore_signal_(signal);
        result->Success(flutter::EncodableValue());
    }
    else if (method == "setFontconfigConfigurationPath") {
        auto path = GetStringArg(args, "path");
        if (fn_set_fontconfig_path_ && !path.empty()) fn_set_fontconfig_path_(path.c_str());
        result->Success(flutter::EncodableValue());
    }
    else if (method == "setFontDirectory") {
        auto path = GetStringArg(args, "fontDirectory");
        auto mappingJson = EncodableMapToJsonObject(GetMapArg(args, "fontNameMap"));
        if (fn_set_font_directory_ && !path.empty()) {
            fn_set_font_directory_(path.c_str(), mappingJson.c_str());
        }
        result->Success(flutter::EncodableValue());
    }
    else if (method == "setFontDirectoryList") {
        auto listJson = EncodableListToJsonArray(GetListArg(args, "fontDirectoryList"));
        auto mappingJson = EncodableMapToJsonObject(GetMapArg(args, "fontNameMap"));
        if (fn_set_font_directory_list_) {
            fn_set_font_directory_list_(listJson.c_str(), mappingJson.c_str());
        }
        result->Success(flutter::EncodableValue());
    }
    else if (method == "registerNewFFmpegPipe") {
        if (fn_register_new_pipe_) {
            char* s = fn_register_new_pipe_();
            if (s) {
                result->Success(flutter::EncodableValue(std::string(s)));
                free_str(s);
            } else result->Success(flutter::EncodableValue());
        } else result->Success(flutter::EncodableValue());
    }
    else if (method == "closeFFmpegPipe") {
        auto path = GetStringArg(args, "ffmpegPipePath");
        if (fn_close_pipe_ && !path.empty()) fn_close_pipe_(path.c_str());
        result->Success(flutter::EncodableValue());
    }
    else if (method == "getSessionHistorySize") {
        if (fn_get_session_history_size_) {
            result->Success(flutter::EncodableValue(fn_get_session_history_size_()));
        } else result->Success(flutter::EncodableValue(0));
    }
    else if (method == "setSessionHistorySize") {
        int size = (int)GetIntArg(args, "sessionHistorySize", 10);
        if (fn_set_session_history_size_) fn_set_session_history_size_(size);
        result->Success(flutter::EncodableValue());
    }
    else if (method == "getSession") {
        long sid = (long)GetIntArg(args, "sessionId");
        if (fn_get_session_json_) {
            char* json = fn_get_session_json_(sid);
            if (json) {
                auto val = ParseJson(json);
                free_str(json);
                result->Success(val);
            } else result->Error("SESSION_NOT_FOUND", "Session not found");
        } else result->Error("SESSION_NOT_FOUND", "Session not found");
    }
    else if (method == "getLastSession") {
        if (fn_get_last_session_json_) {
            char* json = fn_get_last_session_json_();
            if (json) {
                auto val = ParseJson(json);
                free_str(json);
                result->Success(val);
            } else result->Success(flutter::EncodableValue());
        } else result->Success(flutter::EncodableValue());
    }
    else if (method == "getLastCompletedSession") {
        if (fn_get_last_completed_session_json_) {
            char* json = fn_get_last_completed_session_json_();
            if (json) {
                auto val = ParseJson(json);
                free_str(json);
                result->Success(val);
            } else result->Success(flutter::EncodableValue());
        } else result->Success(flutter::EncodableValue());
    }
    else if (method == "getSessions") {
        if (fn_get_sessions_json_) {
            char* json = fn_get_sessions_json_();
            auto list = ParseSessionListJson(json);
            free_str(json);
            result->Success(flutter::EncodableValue(list));
        } else result->Success(flutter::EncodableValue(flutter::EncodableList()));
    }
    else if (method == "clearSessions") {
        if (fn_clear_sessions_) fn_clear_sessions_();
        result->Success(flutter::EncodableValue());
    }
    else if (method == "getSessionsByState") {
        int state = (int)GetIntArg(args, "state", 0);
        if (fn_get_sessions_by_state_json_) {
            char* json = fn_get_sessions_by_state_json_(state);
            auto list = ParseSessionListJson(json);
            free_str(json);
            result->Success(flutter::EncodableValue(list));
        } else result->Success(flutter::EncodableValue(flutter::EncodableList()));
    }
    else if (method == "getLogRedirectionStrategy") {
        if (fn_get_log_redirection_strategy_) {
            result->Success(flutter::EncodableValue(fn_get_log_redirection_strategy_()));
        } else result->Success(flutter::EncodableValue(0));
    }
    else if (method == "setLogRedirectionStrategy") {
        int strategy = (int)GetIntArg(args, "strategy", 0);
        if (fn_set_log_redirection_strategy_) fn_set_log_redirection_strategy_(strategy);
        result->Success(flutter::EncodableValue());
    }
    else if (method == "messagesInTransmit") {
        long sid = (long)GetIntArg(args, "sessionId");
        if (fn_messages_in_transmit_) {
            result->Success(flutter::EncodableValue(fn_messages_in_transmit_(sid)));
        } else result->Success(flutter::EncodableValue(0));
    }
    else if (method == "getPlatform") {
        result->Success(flutter::EncodableValue(std::string("windows")));
    }
    else if (method == "writeToPipe") {
        auto input = GetStringArg(args, "input");
        auto pipe = GetStringArg(args, "pipe");
        if (fn_write_to_pipe_ && !input.empty() && !pipe.empty()) {
            auto shared_result = std::shared_ptr<flutter::MethodResult<flutter::EncodableValue>>(std::move(result));
            std::thread([this, input, pipe, shared_result]() {
                int rc = fn_write_to_pipe_(input.c_str(), pipe.c_str());
                PostToPlatformThread([shared_result, rc]() {
                    shared_result->Success(flutter::EncodableValue(rc));
                });
            }).detach();
            return;
        }
        result->Error("INVALID_ARGUMENTS", "Invalid input or pipe");
    }
    else if (method == "cancel") {
        if (fn_cancel_) fn_cancel_();
        result->Success(flutter::EncodableValue());
    }
    else if (method == "cancelSession") {
        long sid = (long)GetIntArg(args, "sessionId");
        if (fn_cancel_session_) fn_cancel_session_(sid);
        result->Success(flutter::EncodableValue());
    }
    else if (method == "getFFmpegSessions") {
        if (fn_get_ffmpeg_sessions_json_) {
            char* json = fn_get_ffmpeg_sessions_json_();
            auto list = ParseSessionListJson(json);
            free_str(json);
            result->Success(flutter::EncodableValue(list));
        } else result->Success(flutter::EncodableValue(flutter::EncodableList()));
    }
    else if (method == "getFFprobeSessions") {
        if (fn_get_ffprobe_sessions_json_) {
            char* json = fn_get_ffprobe_sessions_json_();
            auto list = ParseSessionListJson(json);
            free_str(json);
            result->Success(flutter::EncodableValue(list));
        } else result->Success(flutter::EncodableValue(flutter::EncodableList()));
    }
    else if (method == "getMediaInformationSessions") {
        if (fn_get_media_info_sessions_json_) {
            char* json = fn_get_media_info_sessions_json_();
            auto list = ParseSessionListJson(json);
            free_str(json);
            result->Success(flutter::EncodableValue(list));
        } else result->Success(flutter::EncodableValue(flutter::EncodableList()));
    }
    else if (method == "getPackageName") {
        if (fn_get_package_name_) {
            char* s = fn_get_package_name_();
            result->Success(flutter::EncodableValue(std::string(s ? s : "")));
            free_str(s);
        } else result->Success(flutter::EncodableValue(""));
    }
    else if (method == "getExternalLibraries") {
        if (fn_get_external_libraries_json_) {
            char* json = fn_get_external_libraries_json_();
            auto val = ParseJsonArray(json);
            free_str(json);
            result->Success(val);
        } else result->Success(flutter::EncodableValue(flutter::EncodableList()));
    }
    else if (method == "selectDocument" || method == "getSafParameter") {
        result->Error("NOT_SUPPORTED", "Not supported on Windows platform");
    }
    else {
        result->NotImplemented();
    }
    } catch (const std::exception& e) {
        // result is null only if it was already moved into a worker thread (an
        // async branch that returned before reaching here); otherwise the reply
        // is still owed, so report the failure instead of leaving Dart hanging.
        if (result) result->Error("EXCEPTION", e.what());
    } catch (...) {
        if (result) result->Error("EXCEPTION", "Unknown native exception");
    }
}

}  // namespace ffmpeg_kit_flutter
