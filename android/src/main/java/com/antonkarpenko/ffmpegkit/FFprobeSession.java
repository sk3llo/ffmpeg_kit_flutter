package com.antonkarpenko.ffmpegkit;

/**
 * <p>An FFprobe session.
 */
public class FFprobeSession extends com.antonkarpenko.ffmpegkit.AbstractSession implements com.antonkarpenko.ffmpegkit.Session {

    /**
     * Session specific complete callback.
     */
    private final com.antonkarpenko.ffmpegkit.FFprobeSessionCompleteCallback completeCallback;

    /**
     * Builds a new FFprobe session.
     *
     * @param arguments command arguments
     * @return created session
     */
    public static FFprobeSession create(final String[] arguments) {
        return new FFprobeSession(arguments, null, null, com.antonkarpenko.ffmpegkit.FFmpegKitConfig.getLogRedirectionStrategy());
    }

    /**
     * Builds a new FFprobe session.
     *
     * @param arguments        command arguments
     * @param completeCallback session specific complete callback
     * @return created session
     */
    public static FFprobeSession create(final String[] arguments, final com.antonkarpenko.ffmpegkit.FFprobeSessionCompleteCallback completeCallback) {
        return new FFprobeSession(arguments, completeCallback, null, com.antonkarpenko.ffmpegkit.FFmpegKitConfig.getLogRedirectionStrategy());
    }

    /**
     * Builds a new FFprobe session.
     *
     * @param arguments        command arguments
     * @param completeCallback session specific complete callback
     * @param logCallback      session specific log callback
     * @return created session
     */
    public static FFprobeSession create(final String[] arguments,
                                        final com.antonkarpenko.ffmpegkit.FFprobeSessionCompleteCallback completeCallback,
                                        final com.antonkarpenko.ffmpegkit.LogCallback logCallback) {
        return new FFprobeSession(arguments, completeCallback, logCallback, com.antonkarpenko.ffmpegkit.FFmpegKitConfig.getLogRedirectionStrategy());
    }

    /**
     * Builds a new FFprobe session.
     *
     * @param arguments              command arguments
     * @param completeCallback       session specific complete callback
     * @param logCallback            session specific log callback
     * @param logRedirectionStrategy session specific log redirection strategy
     * @return created session
     */
    public static FFprobeSession create(final String[] arguments,
                                        final com.antonkarpenko.ffmpegkit.FFprobeSessionCompleteCallback completeCallback,
                                        final com.antonkarpenko.ffmpegkit.LogCallback logCallback,
                                        final com.antonkarpenko.ffmpegkit.LogRedirectionStrategy logRedirectionStrategy) {
        return new FFprobeSession(arguments, completeCallback, logCallback, logRedirectionStrategy);
    }

    /**
     * Builds a new FFprobe session.
     *
     * @param arguments              command arguments
     * @param completeCallback       session specific complete callback
     * @param logCallback            session specific log callback
     * @param logRedirectionStrategy session specific log redirection strategy
     */
    private FFprobeSession(final String[] arguments,
                           final com.antonkarpenko.ffmpegkit.FFprobeSessionCompleteCallback completeCallback,
                           final com.antonkarpenko.ffmpegkit.LogCallback logCallback,
                           final com.antonkarpenko.ffmpegkit.LogRedirectionStrategy logRedirectionStrategy) {
        super(arguments, logCallback, logRedirectionStrategy);

        this.completeCallback = completeCallback;
    }

    /**
     * Returns the session specific complete callback.
     *
     * @return session specific complete callback
     */
    public com.antonkarpenko.ffmpegkit.FFprobeSessionCompleteCallback getCompleteCallback() {
        return completeCallback;
    }

    @Override
    public String getFailStackTrace() {
        return "";
    }

    @Override
    public boolean isFFmpeg() {
        return false;
    }

    @Override
    public boolean isFFprobe() {
        return true;
    }

    @Override
    public boolean isMediaInformation() {
        return false;
    }

    @Override
    public String toString() {
        final StringBuilder stringBuilder = new StringBuilder();

        stringBuilder.append("FFprobeSession{");
        stringBuilder.append("sessionId=");
        stringBuilder.append(sessionId);
        stringBuilder.append(", createTime=");
        stringBuilder.append(createTime);
        stringBuilder.append(", startTime=");
        stringBuilder.append(startTime);
        stringBuilder.append(", endTime=");
        stringBuilder.append(endTime);
        stringBuilder.append(", arguments=");
        stringBuilder.append(com.antonkarpenko.ffmpegkit.FFmpegKitConfig.argumentsToString(arguments));
        stringBuilder.append(", logs=");
        stringBuilder.append(getLogsAsString());
        stringBuilder.append(", state=");
        stringBuilder.append(state);
        stringBuilder.append(", returnCode=");
        stringBuilder.append(returnCode);
        stringBuilder.append(", failStackTrace=");
        stringBuilder.append('\'');
//        stringBuilder.append(failStackTrace);
//        stringBuilder.append('\'');
        stringBuilder.append('}');

        return stringBuilder.toString();
    }

}
