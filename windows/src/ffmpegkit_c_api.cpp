#define FFMPEGKIT_EXPORTS
#include "ffmpegkit_c_api.h"

#include "FFmpegKit.h"
#include "FFmpegKitConfig.h"
#include "FFprobeKit.h"
#include "ArchDetect.h"
#include "Packages.h"
#include "MediaInformationJsonParser.h"
#include "FFmpegKitSignal.h"

#include <rapidjson/document.h>
#include <rapidjson/writer.h>
#include <rapidjson/stringbuffer.h>

#include <cstring>
#include <fstream>
#include <thread>

using namespace ffmpegkit;

static ffmpegkit_log_callback_t g_log_callback = nullptr;
static ffmpegkit_statistics_callback_t g_statistics_callback = nullptr;
static ffmpegkit_session_complete_callback_t g_ffmpeg_complete_callback = nullptr;
static ffmpegkit_session_complete_callback_t g_ffprobe_complete_callback = nullptr;
static ffmpegkit_session_complete_callback_t g_media_info_complete_callback = nullptr;

static char* alloc_string(const std::string& s) {
    char* result = (char*)malloc(s.size() + 1);
    if (result) {
        memcpy(result, s.c_str(), s.size() + 1);
    }
    return result;
}

static char* alloc_string(const char* s) {
    if (!s) return nullptr;
    size_t len = strlen(s);
    char* result = (char*)malloc(len + 1);
    if (result) {
        memcpy(result, s, len + 1);
    }
    return result;
}

static std::list<std::string> to_arg_list(const char** arguments, int count) {
    std::list<std::string> args;
    for (int i = 0; i < count; i++) {
        args.push_back(arguments[i]);
    }
    return args;
}

static int session_type_id(const std::shared_ptr<Session>& session) {
    if (session->isFFmpeg()) return 1;
    if (session->isFFprobe()) return 2;
    if (session->isMediaInformation()) return 3;
    return 0;
}

static std::string session_to_json(const std::shared_ptr<Session>& session) {
    if (!session) return "null";

    rapidjson::StringBuffer sb;
    rapidjson::Writer<rapidjson::StringBuffer> w(sb);
    w.StartObject();
    w.Key("sessionId"); w.Int64(session->getSessionId());
    w.Key("createTime");
    auto ct = std::chrono::duration_cast<std::chrono::milliseconds>(session->getCreateTime().time_since_epoch()).count();
    w.Int64(ct);
    w.Key("startTime");
    auto st = std::chrono::duration_cast<std::chrono::milliseconds>(session->getStartTime().time_since_epoch()).count();
    w.Int64(st);
    w.Key("command"); w.String(session->getCommand().c_str());
    w.Key("type"); w.Int(session_type_id(session));

    if (session->isMediaInformation()) {
        auto mis = std::dynamic_pointer_cast<MediaInformationSession>(session);
        if (mis) {
            auto mi = mis->getMediaInformation();
            if (mi) {
                auto props = mi->getAllProperties();
                if (props) {
                    w.Key("mediaInformation");
                    rapidjson::StringBuffer miSb;
                    rapidjson::Writer<rapidjson::StringBuffer> miW(miSb);
                    props->Accept(miW);
                    w.RawValue(miSb.GetString(), miSb.GetSize(), rapidjson::kObjectType);
                }
            }
        }
    }

    w.EndObject();
    return sb.GetString();
}

static std::string log_to_json(const std::shared_ptr<Log>& log) {
    rapidjson::StringBuffer sb;
    rapidjson::Writer<rapidjson::StringBuffer> w(sb);
    w.StartObject();
    w.Key("sessionId"); w.Int64(log->getSessionId());
    w.Key("level"); w.Int(static_cast<int>(log->getLevel()));
    w.Key("message"); w.String(log->getMessage().c_str());
    w.EndObject();
    return sb.GetString();
}

static std::string statistics_to_json(const std::shared_ptr<Statistics>& stat) {
    rapidjson::StringBuffer sb;
    rapidjson::Writer<rapidjson::StringBuffer> w(sb);
    w.StartObject();
    w.Key("sessionId"); w.Int64(stat->getSessionId());
    w.Key("videoFrameNumber"); w.Int(stat->getVideoFrameNumber());
    w.Key("videoFps"); w.Double(stat->getVideoFps());
    w.Key("videoQuality"); w.Double(stat->getVideoQuality());
    w.Key("size"); w.Int64(stat->getSize());
    w.Key("time"); w.Double(stat->getTime());
    w.Key("bitrate"); w.Double(stat->getBitrate());
    w.Key("speed"); w.Double(stat->getSpeed());
    w.EndObject();
    return sb.GetString();
}

template<typename T>
static std::string list_to_json_array(const std::shared_ptr<std::list<std::shared_ptr<T>>>& items,
                                       std::string (*converter)(const std::shared_ptr<T>&)) {
    std::string result = "[";
    bool first = true;
    if (items) {
        for (auto& item : *items) {
            if (!first) result += ",";
            result += converter(item);
            first = false;
        }
    }
    result += "]";
    return result;
}

// Session creation

extern "C" FFMPEGKIT_API char* ffmpegkit_create_ffmpeg_session(const char** arguments, int count) {
    auto args = to_arg_list(arguments, count);
    auto session = FFmpegSession::create(args, nullptr, nullptr, nullptr, LogRedirectionStrategyNeverPrintLogs);
    return alloc_string(session_to_json(session));
}

extern "C" FFMPEGKIT_API char* ffmpegkit_create_ffprobe_session(const char** arguments, int count) {
    auto args = to_arg_list(arguments, count);
    auto session = FFprobeSession::create(args, nullptr, nullptr, LogRedirectionStrategyNeverPrintLogs);
    return alloc_string(session_to_json(session));
}

extern "C" FFMPEGKIT_API char* ffmpegkit_create_media_information_session(const char** arguments, int count) {
    auto args = to_arg_list(arguments, count);
    auto session = MediaInformationSession::create(args, nullptr, nullptr);
    return alloc_string(session_to_json(session));
}

// Session queries

extern "C" FFMPEGKIT_API int64_t ffmpegkit_session_get_end_time(long session_id) {
    auto session = FFmpegKitConfig::getSession(session_id);
    if (!session) return -1;
    auto endTime = session->getEndTime();
    auto epoch = endTime.time_since_epoch();
    if (epoch.count() == 0) return -1;
    return std::chrono::duration_cast<std::chrono::milliseconds>(epoch).count();
}

extern "C" FFMPEGKIT_API long ffmpegkit_session_get_duration(long session_id) {
    auto session = FFmpegKitConfig::getSession(session_id);
    if (!session) return 0;
    return session->getDuration();
}

extern "C" FFMPEGKIT_API int ffmpegkit_session_get_state(long session_id) {
    auto session = FFmpegKitConfig::getSession(session_id);
    if (!session) return -1;
    return static_cast<int>(session->getState());
}

extern "C" FFMPEGKIT_API int ffmpegkit_session_get_return_code(long session_id) {
    auto session = FFmpegKitConfig::getSession(session_id);
    if (!session) return -1;
    auto rc = session->getReturnCode();
    if (!rc) return -1;
    return rc->getValue();
}

extern "C" FFMPEGKIT_API char* ffmpegkit_session_get_fail_stack_trace(long session_id) {
    auto session = FFmpegKitConfig::getSession(session_id);
    if (!session) return nullptr;
    return alloc_string(session->getFailStackTrace());
}

extern "C" FFMPEGKIT_API int ffmpegkit_session_there_are_async_messages(long session_id) {
    auto session = FFmpegKitConfig::getSession(session_id);
    if (!session) return 0;
    return session->thereAreAsynchronousMessagesInTransmit() ? 1 : 0;
}

extern "C" FFMPEGKIT_API char* ffmpegkit_session_get_command(long session_id) {
    auto session = FFmpegKitConfig::getSession(session_id);
    if (!session) return nullptr;
    return alloc_string(session->getCommand());
}

extern "C" FFMPEGKIT_API char* ffmpegkit_session_get_all_logs_as_string(long session_id, int timeout) {
    auto session = FFmpegKitConfig::getSession(session_id);
    if (!session) return nullptr;
    if (timeout >= 0) {
        return alloc_string(session->getAllLogsAsStringWithTimeout(timeout));
    } else {
        return alloc_string(session->getAllLogsAsString());
    }
}

extern "C" FFMPEGKIT_API char* ffmpegkit_session_get_logs_json(long session_id) {
    auto session = FFmpegKitConfig::getSession(session_id);
    if (!session) return alloc_string("[]");
    auto logs = session->getLogs();
    return alloc_string(list_to_json_array<Log>(logs, log_to_json));
}

extern "C" FFMPEGKIT_API char* ffmpegkit_session_get_all_logs_json(long session_id, int timeout) {
    auto session = FFmpegKitConfig::getSession(session_id);
    if (!session) return alloc_string("[]");
    std::shared_ptr<std::list<std::shared_ptr<Log>>> logs;
    if (timeout >= 0) {
        logs = session->getAllLogsWithTimeout(timeout);
    } else {
        logs = session->getAllLogs();
    }
    return alloc_string(list_to_json_array<Log>(logs, log_to_json));
}

extern "C" FFMPEGKIT_API char* ffmpegkit_session_get_statistics_json(long session_id) {
    auto session = FFmpegKitConfig::getSession(session_id);
    if (!session) return alloc_string("[]");
    if (!session->isFFmpeg()) return alloc_string("[]");
    auto ffmpegSession = std::dynamic_pointer_cast<FFmpegSession>(session);
    if (!ffmpegSession) return alloc_string("[]");
    auto stats = ffmpegSession->getStatistics();
    return alloc_string(list_to_json_array<Statistics>(stats, statistics_to_json));
}

extern "C" FFMPEGKIT_API char* ffmpegkit_session_get_all_statistics_json(long session_id, int timeout) {
    auto session = FFmpegKitConfig::getSession(session_id);
    if (!session) return alloc_string("[]");
    if (!session->isFFmpeg()) return alloc_string("[]");
    auto ffmpegSession = std::dynamic_pointer_cast<FFmpegSession>(session);
    if (!ffmpegSession) return alloc_string("[]");
    std::shared_ptr<std::list<std::shared_ptr<Statistics>>> stats;
    if (timeout >= 0) {
        stats = ffmpegSession->getAllStatisticsWithTimeout(timeout);
    } else {
        stats = ffmpegSession->getAllStatistics();
    }
    return alloc_string(list_to_json_array<Statistics>(stats, statistics_to_json));
}

extern "C" FFMPEGKIT_API char* ffmpegkit_session_get_json(long session_id) {
    auto session = FFmpegKitConfig::getSession(session_id);
    if (!session) return nullptr;
    return alloc_string(session_to_json(session));
}

// Execution

extern "C" FFMPEGKIT_API void ffmpegkit_ffmpeg_execute(long session_id) {
    auto session = FFmpegKitConfig::getSession(session_id);
    if (session && session->isFFmpeg()) {
        FFmpegKitConfig::ffmpegExecute(std::dynamic_pointer_cast<FFmpegSession>(session));
    }
}

extern "C" FFMPEGKIT_API void ffmpegkit_ffprobe_execute(long session_id) {
    auto session = FFmpegKitConfig::getSession(session_id);
    if (session && session->isFFprobe()) {
        FFmpegKitConfig::ffprobeExecute(std::dynamic_pointer_cast<FFprobeSession>(session));
    }
}

extern "C" FFMPEGKIT_API void ffmpegkit_media_information_execute(long session_id, int timeout) {
    auto session = FFmpegKitConfig::getSession(session_id);
    if (session && session->isMediaInformation()) {
        FFmpegKitConfig::getMediaInformationExecute(
            std::dynamic_pointer_cast<MediaInformationSession>(session), timeout);
    }
}

extern "C" FFMPEGKIT_API void ffmpegkit_async_ffmpeg_execute(long session_id) {
    auto session = FFmpegKitConfig::getSession(session_id);
    if (session && session->isFFmpeg()) {
        FFmpegKitConfig::asyncFFmpegExecute(std::dynamic_pointer_cast<FFmpegSession>(session));
    }
}

extern "C" FFMPEGKIT_API void ffmpegkit_async_ffprobe_execute(long session_id) {
    auto session = FFmpegKitConfig::getSession(session_id);
    if (session && session->isFFprobe()) {
        FFmpegKitConfig::asyncFFprobeExecute(std::dynamic_pointer_cast<FFprobeSession>(session));
    }
}

extern "C" FFMPEGKIT_API void ffmpegkit_async_media_information_execute(long session_id, int timeout) {
    auto session = FFmpegKitConfig::getSession(session_id);
    if (session && session->isMediaInformation()) {
        FFmpegKitConfig::asyncGetMediaInformationExecute(
            std::dynamic_pointer_cast<MediaInformationSession>(session), timeout);
    }
}

// Cancel

extern "C" FFMPEGKIT_API void ffmpegkit_cancel() {
    FFmpegKit::cancel();
}

extern "C" FFMPEGKIT_API void ffmpegkit_cancel_session(long session_id) {
    FFmpegKit::cancel(session_id);
}

// Config

extern "C" FFMPEGKIT_API void ffmpegkit_enable_redirection() {
    FFmpegKitConfig::enableRedirection();
}

extern "C" FFMPEGKIT_API void ffmpegkit_disable_redirection() {
    FFmpegKitConfig::disableRedirection();
}

extern "C" FFMPEGKIT_API int ffmpegkit_get_log_level() {
    return static_cast<int>(FFmpegKitConfig::getLogLevel());
}

extern "C" FFMPEGKIT_API void ffmpegkit_set_log_level(int level) {
    FFmpegKitConfig::setLogLevel(static_cast<Level>(level));
}

extern "C" FFMPEGKIT_API char* ffmpegkit_get_ffmpeg_version() {
    return alloc_string(FFmpegKitConfig::getFFmpegVersion());
}

extern "C" FFMPEGKIT_API int ffmpegkit_is_lts_build() {
    return FFmpegKitConfig::isLTSBuild() ? 1 : 0;
}

extern "C" FFMPEGKIT_API char* ffmpegkit_get_build_date() {
    return alloc_string(FFmpegKitConfig::getBuildDate());
}

extern "C" FFMPEGKIT_API void ffmpegkit_set_environment_variable(const char* name, const char* value) {
    if (name && value) {
        FFmpegKitConfig::setEnvironmentVariable(name, value);
    }
}

extern "C" FFMPEGKIT_API void ffmpegkit_ignore_signal(int signal_index) {
    Signal sig;
    switch (signal_index) {
        case 0: sig = SignalInt; break;
        case 1: sig = SignalQuit; break;
        case 2: sig = SignalPipe; break;
        case 3: sig = SignalTerm; break;
        case 4: sig = SignalXcpu; break;
        default: return;
    }
    FFmpegKitConfig::ignoreSignal(sig);
}

extern "C" FFMPEGKIT_API int ffmpegkit_get_session_history_size() {
    return FFmpegKitConfig::getSessionHistorySize();
}

extern "C" FFMPEGKIT_API void ffmpegkit_set_session_history_size(int size) {
    FFmpegKitConfig::setSessionHistorySize(size);
}

extern "C" FFMPEGKIT_API char* ffmpegkit_register_new_pipe() {
    auto pipe = FFmpegKitConfig::registerNewFFmpegPipe();
    if (pipe) {
        return alloc_string(*pipe);
    }
    return nullptr;
}

extern "C" FFMPEGKIT_API void ffmpegkit_close_pipe(const char* path) {
    if (path) {
        FFmpegKitConfig::closeFFmpegPipe(path);
    }
}

extern "C" FFMPEGKIT_API void ffmpegkit_set_fontconfig_configuration_path(const char* path) {
    if (path) {
        FFmpegKitConfig::setFontconfigConfigurationPath(path);
    }
}

extern "C" FFMPEGKIT_API void ffmpegkit_set_font_directory(const char* path, const char* mapping_json) {
    if (!path) return;
    std::map<std::string, std::string> mapping;
    if (mapping_json) {
        rapidjson::Document doc;
        doc.Parse(mapping_json);
        if (doc.IsObject()) {
            for (auto it = doc.MemberBegin(); it != doc.MemberEnd(); ++it) {
                if (it->value.IsString()) {
                    mapping[it->name.GetString()] = it->value.GetString();
                }
            }
        }
    }
    FFmpegKitConfig::setFontDirectory(path, mapping);
}

extern "C" FFMPEGKIT_API void ffmpegkit_set_font_directory_list(const char* list_json, const char* mapping_json) {
    if (!list_json) return;
    std::list<std::string> dirs;
    rapidjson::Document listDoc;
    listDoc.Parse(list_json);
    if (listDoc.IsArray()) {
        for (auto& v : listDoc.GetArray()) {
            if (v.IsString()) dirs.push_back(v.GetString());
        }
    }
    std::map<std::string, std::string> mapping;
    if (mapping_json) {
        rapidjson::Document mapDoc;
        mapDoc.Parse(mapping_json);
        if (mapDoc.IsObject()) {
            for (auto it = mapDoc.MemberBegin(); it != mapDoc.MemberEnd(); ++it) {
                if (it->value.IsString()) {
                    mapping[it->name.GetString()] = it->value.GetString();
                }
            }
        }
    }
    FFmpegKitConfig::setFontDirectoryList(dirs, mapping);
}

extern "C" FFMPEGKIT_API int ffmpegkit_get_log_redirection_strategy() {
    return static_cast<int>(FFmpegKitConfig::getLogRedirectionStrategy());
}

extern "C" FFMPEGKIT_API void ffmpegkit_set_log_redirection_strategy(int strategy) {
    FFmpegKitConfig::setLogRedirectionStrategy(static_cast<LogRedirectionStrategy>(strategy));
}

extern "C" FFMPEGKIT_API int ffmpegkit_messages_in_transmit(long session_id) {
    return FFmpegKitConfig::messagesInTransmit(session_id);
}

extern "C" FFMPEGKIT_API char* ffmpegkit_get_platform() {
    return alloc_string("windows");
}

extern "C" FFMPEGKIT_API int ffmpegkit_write_to_pipe(const char* input_path, const char* pipe_path) {
    if (!input_path || !pipe_path) return -1;
    std::ifstream input(input_path, std::ios::binary);
    if (!input.is_open()) return -1;
    std::ofstream pipe(pipe_path, std::ios::binary);
    if (!pipe.is_open()) return -1;
    char buffer[4096];
    while (input.read(buffer, sizeof(buffer)) || input.gcount() > 0) {
        pipe.write(buffer, input.gcount());
    }
    return 0;
}

// Session management

extern "C" FFMPEGKIT_API char* ffmpegkit_get_session_json(long session_id) {
    auto session = FFmpegKitConfig::getSession(session_id);
    if (!session) return nullptr;
    return alloc_string(session_to_json(session));
}

extern "C" FFMPEGKIT_API char* ffmpegkit_get_last_session_json() {
    auto session = FFmpegKitConfig::getLastSession();
    if (!session) return nullptr;
    return alloc_string(session_to_json(session));
}

extern "C" FFMPEGKIT_API char* ffmpegkit_get_last_completed_session_json() {
    auto session = FFmpegKitConfig::getLastCompletedSession();
    if (!session) return nullptr;
    return alloc_string(session_to_json(session));
}

extern "C" FFMPEGKIT_API char* ffmpegkit_get_sessions_json() {
    auto sessions = FFmpegKitConfig::getSessions();
    return alloc_string(list_to_json_array<Session>(sessions, session_to_json));
}

extern "C" FFMPEGKIT_API void ffmpegkit_clear_sessions() {
    FFmpegKitConfig::clearSessions();
}

extern "C" FFMPEGKIT_API char* ffmpegkit_get_sessions_by_state_json(int state) {
    auto sessions = FFmpegKitConfig::getSessionsByState(static_cast<SessionState>(state));
    return alloc_string(list_to_json_array<Session>(sessions, session_to_json));
}

extern "C" FFMPEGKIT_API char* ffmpegkit_get_ffmpeg_sessions_json() {
    auto sessions = FFmpegKit::listSessions();
    std::string result = "[";
    bool first = true;
    if (sessions) {
        for (auto& s : *sessions) {
            if (!first) result += ",";
            result += session_to_json(s);
            first = false;
        }
    }
    result += "]";
    return alloc_string(result);
}

extern "C" FFMPEGKIT_API char* ffmpegkit_get_ffprobe_sessions_json() {
    auto sessions = FFprobeKit::listFFprobeSessions();
    std::string result = "[";
    bool first = true;
    if (sessions) {
        for (auto& s : *sessions) {
            if (!first) result += ",";
            result += session_to_json(s);
            first = false;
        }
    }
    result += "]";
    return alloc_string(result);
}

extern "C" FFMPEGKIT_API char* ffmpegkit_get_media_information_sessions_json() {
    auto sessions = FFprobeKit::listMediaInformationSessions();
    std::string result = "[";
    bool first = true;
    if (sessions) {
        for (auto& s : *sessions) {
            if (!first) result += ",";
            result += session_to_json(s);
            first = false;
        }
    }
    result += "]";
    return alloc_string(result);
}

// Media information

extern "C" FFMPEGKIT_API char* ffmpegkit_get_media_information_json(long session_id) {
    auto session = FFmpegKitConfig::getSession(session_id);
    if (!session || !session->isMediaInformation()) return nullptr;
    auto mis = std::dynamic_pointer_cast<MediaInformationSession>(session);
    if (!mis) return nullptr;
    auto mi = mis->getMediaInformation();
    if (!mi) return nullptr;
    auto props = mi->getAllProperties();
    if (!props) return nullptr;
    rapidjson::StringBuffer sb;
    rapidjson::Writer<rapidjson::StringBuffer> w(sb);
    props->Accept(w);
    return alloc_string(std::string(sb.GetString()));
}

extern "C" FFMPEGKIT_API char* ffmpegkit_media_information_json_parser_from(const char* json_output) {
    if (!json_output) return nullptr;
    try {
        auto mi = MediaInformationJsonParser::from(json_output);
        if (!mi) return nullptr;
        auto props = mi->getAllProperties();
        if (!props) return nullptr;
        rapidjson::StringBuffer sb;
        rapidjson::Writer<rapidjson::StringBuffer> w(sb);
        props->Accept(w);
        return alloc_string(std::string(sb.GetString()));
    } catch (...) {
        return nullptr;
    }
}

extern "C" FFMPEGKIT_API char* ffmpegkit_media_information_json_parser_from_with_error(const char* json_output) {
    if (!json_output) return nullptr;
    auto mi = MediaInformationJsonParser::fromWithError(json_output);
    if (!mi) return nullptr;
    auto props = mi->getAllProperties();
    if (!props) return nullptr;
    rapidjson::StringBuffer sb;
    rapidjson::Writer<rapidjson::StringBuffer> w(sb);
    props->Accept(w);
    return alloc_string(std::string(sb.GetString()));
}

// Packages

extern "C" FFMPEGKIT_API char* ffmpegkit_get_package_name() {
    return alloc_string(Packages::getPackageName());
}

extern "C" FFMPEGKIT_API char* ffmpegkit_get_external_libraries_json() {
    auto libs = Packages::getExternalLibraries();
    std::string result = "[";
    bool first = true;
    if (libs) {
        for (auto& lib : *libs) {
            if (!first) result += ",";
            result += "\"" + lib + "\"";
            first = false;
        }
    }
    result += "]";
    return alloc_string(result);
}

// Architecture

extern "C" FFMPEGKIT_API char* ffmpegkit_get_arch() {
    return alloc_string(ArchDetect::getArch());
}

// Callbacks

extern "C" FFMPEGKIT_API void ffmpegkit_enable_log_callback(ffmpegkit_log_callback_t callback) {
    g_log_callback = callback;
    if (callback) {
        FFmpegKitConfig::enableLogCallback([](const std::shared_ptr<Log> log) {
            if (g_log_callback && log) {
                g_log_callback(log->getSessionId(), static_cast<int>(log->getLevel()),
                               log->getMessage().c_str());
            }
        });
    } else {
        FFmpegKitConfig::enableLogCallback(nullptr);
    }
}

extern "C" FFMPEGKIT_API void ffmpegkit_enable_statistics_callback(ffmpegkit_statistics_callback_t callback) {
    g_statistics_callback = callback;
    if (callback) {
        FFmpegKitConfig::enableStatisticsCallback([](const std::shared_ptr<Statistics> stat) {
            if (g_statistics_callback && stat) {
                g_statistics_callback(stat->getSessionId(), stat->getVideoFrameNumber(),
                    stat->getVideoFps(), stat->getVideoQuality(), stat->getSize(),
                    stat->getTime(), stat->getBitrate(), stat->getSpeed());
            }
        });
    } else {
        FFmpegKitConfig::enableStatisticsCallback(nullptr);
    }
}

extern "C" FFMPEGKIT_API void ffmpegkit_enable_ffmpeg_session_complete_callback(ffmpegkit_session_complete_callback_t callback) {
    g_ffmpeg_complete_callback = callback;
    if (callback) {
        FFmpegKitConfig::enableFFmpegSessionCompleteCallback(
            [](const std::shared_ptr<FFmpegSession> session) {
                if (g_ffmpeg_complete_callback && session) {
                    g_ffmpeg_complete_callback(session->getSessionId(), 1);
                }
            });
    } else {
        FFmpegKitConfig::enableFFmpegSessionCompleteCallback(nullptr);
    }
}

extern "C" FFMPEGKIT_API void ffmpegkit_enable_ffprobe_session_complete_callback(ffmpegkit_session_complete_callback_t callback) {
    g_ffprobe_complete_callback = callback;
    if (callback) {
        FFmpegKitConfig::enableFFprobeSessionCompleteCallback(
            [](const std::shared_ptr<FFprobeSession> session) {
                if (g_ffprobe_complete_callback && session) {
                    g_ffprobe_complete_callback(session->getSessionId(), 2);
                }
            });
    } else {
        FFmpegKitConfig::enableFFprobeSessionCompleteCallback(nullptr);
    }
}

extern "C" FFMPEGKIT_API void ffmpegkit_enable_media_information_session_complete_callback(ffmpegkit_session_complete_callback_t callback) {
    g_media_info_complete_callback = callback;
    if (callback) {
        FFmpegKitConfig::enableMediaInformationSessionCompleteCallback(
            [](const std::shared_ptr<MediaInformationSession> session) {
                if (g_media_info_complete_callback && session) {
                    g_media_info_complete_callback(session->getSessionId(), 3);
                }
            });
    } else {
        FFmpegKitConfig::enableMediaInformationSessionCompleteCallback(nullptr);
    }
}

// Memory management

extern "C" FFMPEGKIT_API void ffmpegkit_free(void* ptr) {
    free(ptr);
}
