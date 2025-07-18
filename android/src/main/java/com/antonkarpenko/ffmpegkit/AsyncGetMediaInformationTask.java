package com.antonkarpenko.ffmpegkit;

/**
 * <p>Executes a MediaInformation session asynchronously.
 */
public class AsyncGetMediaInformationTask implements Runnable {
    private final com.antonkarpenko.ffmpegkit.MediaInformationSession mediaInformationSession;
    private final com.antonkarpenko.ffmpegkit.MediaInformationSessionCompleteCallback completeCallback;
    private final Integer waitTimeout;

    public AsyncGetMediaInformationTask(final com.antonkarpenko.ffmpegkit.MediaInformationSession mediaInformationSession) {
        this(mediaInformationSession, com.antonkarpenko.ffmpegkit.AbstractSession.DEFAULT_TIMEOUT_FOR_ASYNCHRONOUS_MESSAGES_IN_TRANSMIT);
    }

    public AsyncGetMediaInformationTask(final com.antonkarpenko.ffmpegkit.MediaInformationSession mediaInformationSession, final Integer waitTimeout) {
        this.mediaInformationSession = mediaInformationSession;
        this.completeCallback = mediaInformationSession.getCompleteCallback();
        this.waitTimeout = waitTimeout;
    }

    @Override
    public void run() {
        com.antonkarpenko.ffmpegkit.FFmpegKitConfig.getMediaInformationExecute(mediaInformationSession, waitTimeout);

        if (completeCallback != null) {
            try {
                // NOTIFY SESSION CALLBACK DEFINED
                completeCallback.apply(mediaInformationSession);
            } catch (final Exception e) {
//                android.util.Log.e(FFmpegKitConfig.TAG, String.format("Exception thrown inside session complete callback.%s", Exceptions.getStackTraceString(e)));
            }
        }

        final com.antonkarpenko.ffmpegkit.MediaInformationSessionCompleteCallback globalMediaInformationSessionCompleteCallback = com.antonkarpenko.ffmpegkit.FFmpegKitConfig.getMediaInformationSessionCompleteCallback();
        if (globalMediaInformationSessionCompleteCallback != null) {
            try {
                // NOTIFY GLOBAL CALLBACK DEFINEDs
                globalMediaInformationSessionCompleteCallback.apply(mediaInformationSession);
            } catch (final Exception e) {
//                android.util.Log.e(FFmpegKitConfig.TAG, String.format("Exception thrown inside global complete callback.%s", Exceptions.getStackTraceString(e)));
            }
        }
    }

}
