package com.antonkarpenko.ffmpegkit;

/**
 * <p>Callback function that is invoked when an asynchronous <code>FFmpeg</code> session has ended.
 */
@FunctionalInterface
public interface FFmpegSessionCompleteCallback {

    /**
     * <p>Called when an FFmpeg session has ended.
     *
     * @param session FFmpeg session
     */
    void apply(final com.antonkarpenko.ffmpegkit.FFmpegSession session);

}
