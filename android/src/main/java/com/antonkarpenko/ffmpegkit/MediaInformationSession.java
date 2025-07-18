package com.antonkarpenko.ffmpegkit;

/**
 * <p>A custom FFprobe session, which produces a <code>MediaInformation</code> object using the
 * FFprobe output.
 */
public class MediaInformationSession extends com.antonkarpenko.ffmpegkit.AbstractSession implements com.antonkarpenko.ffmpegkit.Session {

    /**
     * Media information extracted in the session.
     */
    private com.antonkarpenko.ffmpegkit.MediaInformation mediaInformation;

    /**
     * Session specific complete callback.
     */
    private final com.antonkarpenko.ffmpegkit.MediaInformationSessionCompleteCallback completeCallback;

    /**
     * Creates a new media information session.
     *
     * @param arguments command arguments
     * @return created session
     */
    public static MediaInformationSession create(final String[] arguments) {
        return new MediaInformationSession(arguments, null, null);
    }

    /**
     * Creates a new media information session.
     *
     * @param arguments        command arguments
     * @param completeCallback session specific complete callback
     * @return created session
     */
    public static MediaInformationSession create(final String[] arguments, final com.antonkarpenko.ffmpegkit.MediaInformationSessionCompleteCallback completeCallback) {
        return new MediaInformationSession(arguments, completeCallback, null);
    }

    /**
     * Creates a new media information session.
     *
     * @param arguments        command arguments
     * @param completeCallback session specific complete callback
     * @param logCallback      session specific log callback
     * @return created session
     */
    public static MediaInformationSession create(final String[] arguments, final com.antonkarpenko.ffmpegkit.MediaInformationSessionCompleteCallback completeCallback, final com.antonkarpenko.ffmpegkit.LogCallback logCallback) {
        return new MediaInformationSession(arguments, completeCallback, logCallback);
    }

    /**
     * Creates a new media information session.
     *
     * @param arguments        command arguments
     * @param completeCallback session specific complete callback
     * @param logCallback      session specific log callback
     */
    private MediaInformationSession(final String[] arguments, final com.antonkarpenko.ffmpegkit.MediaInformationSessionCompleteCallback completeCallback, final com.antonkarpenko.ffmpegkit.LogCallback logCallback) {
        super(arguments, logCallback, com.antonkarpenko.ffmpegkit.LogRedirectionStrategy.NEVER_PRINT_LOGS);

        this.completeCallback = completeCallback;
    }

    /**
     * Returns the media information extracted in this session.
     *
     * @return media information extracted or null if the command failed or the output can not be
     * parsed
     */
    public com.antonkarpenko.ffmpegkit.MediaInformation getMediaInformation() {
        return mediaInformation;
    }

    /**
     * Sets the media information extracted in this session.
     *
     * @param mediaInformation media information extracted
     */
    public void setMediaInformation(final com.antonkarpenko.ffmpegkit.MediaInformation mediaInformation) {
        this.mediaInformation = mediaInformation;
    }

    /**
     * Returns the session specific complete callback.
     *
     * @return session specific complete callback
     */
    public com.antonkarpenko.ffmpegkit.MediaInformationSessionCompleteCallback getCompleteCallback() {
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
        return false;
    }

    @Override
    public boolean isMediaInformation() {
        return true;
    }

    @Override
    public String toString() {
        final StringBuilder stringBuilder = new StringBuilder();

        stringBuilder.append("MediaInformationSession{");
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
