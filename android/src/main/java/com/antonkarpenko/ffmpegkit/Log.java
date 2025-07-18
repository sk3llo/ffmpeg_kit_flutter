package com.antonkarpenko.ffmpegkit;

/**
 * <p>Log entry for an <code>FFmpegKit</code> session.
 */
public class Log {
    private final long sessionId;
    private final com.antonkarpenko.ffmpegkit.Level level;
    private final String message;

    public Log(final long sessionId, final com.antonkarpenko.ffmpegkit.Level level, final String message) {
        this.sessionId = sessionId;
        this.level = level;
        this.message = message;
    }

    public long getSessionId() {
        return sessionId;
    }

    public com.antonkarpenko.ffmpegkit.Level getLevel() {
        return level;
    }

    public String getMessage() {
        return message;
    }

    @Override
    public String toString() {
        final StringBuilder stringBuilder = new StringBuilder();

        stringBuilder.append("Log{");
        stringBuilder.append("sessionId=");
        stringBuilder.append(sessionId);
        stringBuilder.append(", level=");
        stringBuilder.append(level);
        stringBuilder.append(", message=");
        stringBuilder.append("\'");
        stringBuilder.append(message);
        stringBuilder.append('\'');
        stringBuilder.append('}');

        return stringBuilder.toString();
    }
}
