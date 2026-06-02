#ifndef FFMPEGKIT_C_API_H
#define FFMPEGKIT_C_API_H

#ifdef __cplusplus
extern "C" {
#endif

#ifdef _WIN32
  #ifdef FFMPEGKIT_EXPORTS
    #define FFMPEGKIT_API __declspec(dllexport)
  #else
    #define FFMPEGKIT_API __declspec(dllimport)
  #endif
#else
  #define FFMPEGKIT_API
#endif

#include <stdint.h>

typedef void (*ffmpegkit_log_callback_t)(long session_id, int level, const char* message);
typedef void (*ffmpegkit_statistics_callback_t)(long session_id, int video_frame_number,
    float video_fps, float video_quality, int64_t size, double time, double bitrate, double speed);
typedef void (*ffmpegkit_session_complete_callback_t)(long session_id, int session_type);

// Session creation - returns session ID. Caller must free returned JSON with ffmpegkit_free.
FFMPEGKIT_API char* ffmpegkit_create_ffmpeg_session(const char** arguments, int count);
FFMPEGKIT_API char* ffmpegkit_create_ffprobe_session(const char** arguments, int count);
FFMPEGKIT_API char* ffmpegkit_create_media_information_session(const char** arguments, int count);

// Session queries
FFMPEGKIT_API int64_t ffmpegkit_session_get_end_time(long session_id);
FFMPEGKIT_API long ffmpegkit_session_get_duration(long session_id);
FFMPEGKIT_API int ffmpegkit_session_get_state(long session_id);
FFMPEGKIT_API int ffmpegkit_session_get_return_code(long session_id);
FFMPEGKIT_API char* ffmpegkit_session_get_fail_stack_trace(long session_id);
FFMPEGKIT_API int ffmpegkit_session_there_are_async_messages(long session_id);
FFMPEGKIT_API char* ffmpegkit_session_get_command(long session_id);
FFMPEGKIT_API char* ffmpegkit_session_get_all_logs_as_string(long session_id, int timeout);
FFMPEGKIT_API char* ffmpegkit_session_get_logs_json(long session_id);
FFMPEGKIT_API char* ffmpegkit_session_get_all_logs_json(long session_id, int timeout);
FFMPEGKIT_API char* ffmpegkit_session_get_statistics_json(long session_id);
FFMPEGKIT_API char* ffmpegkit_session_get_all_statistics_json(long session_id, int timeout);
FFMPEGKIT_API char* ffmpegkit_session_get_json(long session_id);

// Execution
FFMPEGKIT_API void ffmpegkit_ffmpeg_execute(long session_id);
FFMPEGKIT_API void ffmpegkit_ffprobe_execute(long session_id);
FFMPEGKIT_API void ffmpegkit_media_information_execute(long session_id, int timeout);
FFMPEGKIT_API void ffmpegkit_async_ffmpeg_execute(long session_id);
FFMPEGKIT_API void ffmpegkit_async_ffprobe_execute(long session_id);
FFMPEGKIT_API void ffmpegkit_async_media_information_execute(long session_id, int timeout);

// Cancel
FFMPEGKIT_API void ffmpegkit_cancel();
FFMPEGKIT_API void ffmpegkit_cancel_session(long session_id);

// Config
FFMPEGKIT_API void ffmpegkit_enable_redirection();
FFMPEGKIT_API void ffmpegkit_disable_redirection();
FFMPEGKIT_API int ffmpegkit_get_log_level();
FFMPEGKIT_API void ffmpegkit_set_log_level(int level);
FFMPEGKIT_API char* ffmpegkit_get_ffmpeg_version();
FFMPEGKIT_API int ffmpegkit_is_lts_build();
FFMPEGKIT_API char* ffmpegkit_get_build_date();
FFMPEGKIT_API void ffmpegkit_set_environment_variable(const char* name, const char* value);
FFMPEGKIT_API void ffmpegkit_ignore_signal(int signal);
FFMPEGKIT_API int ffmpegkit_get_session_history_size();
FFMPEGKIT_API void ffmpegkit_set_session_history_size(int size);
FFMPEGKIT_API char* ffmpegkit_register_new_pipe();
FFMPEGKIT_API void ffmpegkit_close_pipe(const char* path);
FFMPEGKIT_API void ffmpegkit_set_fontconfig_configuration_path(const char* path);
FFMPEGKIT_API void ffmpegkit_set_font_directory(const char* path, const char* mapping_json);
FFMPEGKIT_API void ffmpegkit_set_font_directory_list(const char* list_json, const char* mapping_json);
FFMPEGKIT_API int ffmpegkit_get_log_redirection_strategy();
FFMPEGKIT_API void ffmpegkit_set_log_redirection_strategy(int strategy);
FFMPEGKIT_API int ffmpegkit_messages_in_transmit(long session_id);
FFMPEGKIT_API char* ffmpegkit_get_platform();
FFMPEGKIT_API int ffmpegkit_write_to_pipe(const char* input_path, const char* pipe_path);

// Session management
FFMPEGKIT_API char* ffmpegkit_get_session_json(long session_id);
FFMPEGKIT_API char* ffmpegkit_get_last_session_json();
FFMPEGKIT_API char* ffmpegkit_get_last_completed_session_json();
FFMPEGKIT_API char* ffmpegkit_get_sessions_json();
FFMPEGKIT_API void ffmpegkit_clear_sessions();
FFMPEGKIT_API char* ffmpegkit_get_sessions_by_state_json(int state);
FFMPEGKIT_API char* ffmpegkit_get_ffmpeg_sessions_json();
FFMPEGKIT_API char* ffmpegkit_get_ffprobe_sessions_json();
FFMPEGKIT_API char* ffmpegkit_get_media_information_sessions_json();

// Media information
FFMPEGKIT_API char* ffmpegkit_get_media_information_json(long session_id);
FFMPEGKIT_API char* ffmpegkit_media_information_json_parser_from(const char* json_output);
FFMPEGKIT_API char* ffmpegkit_media_information_json_parser_from_with_error(const char* json_output);

// Packages
FFMPEGKIT_API char* ffmpegkit_get_package_name();
FFMPEGKIT_API char* ffmpegkit_get_external_libraries_json();

// Architecture
FFMPEGKIT_API char* ffmpegkit_get_arch();

// Callbacks
FFMPEGKIT_API void ffmpegkit_enable_log_callback(ffmpegkit_log_callback_t callback);
FFMPEGKIT_API void ffmpegkit_enable_statistics_callback(ffmpegkit_statistics_callback_t callback);
FFMPEGKIT_API void ffmpegkit_enable_ffmpeg_session_complete_callback(ffmpegkit_session_complete_callback_t callback);
FFMPEGKIT_API void ffmpegkit_enable_ffprobe_session_complete_callback(ffmpegkit_session_complete_callback_t callback);
FFMPEGKIT_API void ffmpegkit_enable_media_information_session_complete_callback(ffmpegkit_session_complete_callback_t callback);

// Memory management - must free all returned char* through this function
FFMPEGKIT_API void ffmpegkit_free(void* ptr);

#ifdef __cplusplus
}
#endif

#endif // FFMPEGKIT_C_API_H
