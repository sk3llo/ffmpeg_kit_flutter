/*
 * Copyright (c) 2020-2021 Taner Sener
 *
 * This file is part of FFmpegKit.
 *
 * FFmpegKit is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * FFmpegKit is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with FFmpegKit.  If not, see <http://www.gnu.org/licenses/>.
 */

package com.antonkarpenko.ffmpegkit;

import java.util.List;
import java.util.concurrent.ExecutorService;

/**
 * <p>Main class to run <code>FFprobe</code> commands. Supports executing commands both
 * synchronously and asynchronously.
 * <pre>
 * FFprobeSession session = FFprobeKit.execute("-hide_banner -v error -show_entries format=size -of default=noprint_wrappers=1 file1.mp4");
 *
 * FFprobeSession asyncSession = FFprobeKit.executeAsync("-hide_banner -v error -show_entries format=size -of default=noprint_wrappers=1 file1.mp4", completeCallback);
 * </pre>
 * <p>Provides overloaded <code>execute</code> methods to define session specific callbacks.
 * <pre>
 * FFprobeSession session = FFprobeKit.executeAsync("-hide_banner -v error -show_entries format=size -of default=noprint_wrappers=1 file1.mp4", completeCallback, logCallback);
 * </pre>
 * <p>It can extract media information for a file or a url, using {@link #getMediaInformation(String)} method.
 * <pre>
 * MediaInformationSession session = FFprobeKit.getMediaInformation("file1.mp4");
 * </pre>
 */
public class FFprobeKit {

    static {
        com.antonkarpenko.ffmpegkit.AbiDetect.class.getName();
        com.antonkarpenko.ffmpegkit.FFmpegKitConfig.class.getName();
    }

    /**
     * Default constructor hidden.
     */
    private FFprobeKit() {
    }

    /**
     * <p>Builds the default command used to get media information for a file.
     *
     * @param path file path to use in the command
     * @return default command arguments to get media information
     */
    private static String[] defaultGetMediaInformationCommandArguments(final String path) {
        return new String[]{"-v", "error", "-hide_banner", "-print_format", "json", "-show_format", "-show_streams", "-show_chapters", "-i", path};
    }

    /**
     * <p>Synchronously executes FFprobe with arguments provided.
     *
     * @param arguments FFprobe command options/arguments as string array
     * @return FFprobe session created for this execution
     */
    public static com.antonkarpenko.ffmpegkit.FFprobeSession executeWithArguments(final String[] arguments) {
        final com.antonkarpenko.ffmpegkit.FFprobeSession session = com.antonkarpenko.ffmpegkit.FFprobeSession.create(arguments);

        com.antonkarpenko.ffmpegkit.FFmpegKitConfig.ffprobeExecute(session);

        return session;
    }

    /**
     * <p>Starts an asynchronous FFprobe execution with arguments provided.
     *
     * <p>Note that this method returns immediately and does not wait the execution to complete.
     * You must use an {@link 'FFprobeSessionCompleteCallback'} if you want to be notified about the
     * result.
     *
     * @param arguments        FFprobe command options/arguments as string array
     * @param completeCallback callback that will be called when the execution has completed
     * @return FFprobe session created for this execution
     */
    public static com.antonkarpenko.ffmpegkit.FFprobeSession executeWithArgumentsAsync(final String[] arguments,
                                                           final com.antonkarpenko.ffmpegkit.FFprobeSessionCompleteCallback completeCallback) {
        final com.antonkarpenko.ffmpegkit.FFprobeSession session = com.antonkarpenko.ffmpegkit.FFprobeSession.create(arguments, completeCallback);

        com.antonkarpenko.ffmpegkit.FFmpegKitConfig.asyncFFprobeExecute(session);

        return session;
    }

    /**
     * <p>Starts an asynchronous FFprobe execution with arguments provided.
     *
     * <p>Note that this method returns immediately and does not wait the execution to complete.
     * You must use an {@link com.antonkarpenko.ffmpegkit.FFprobeSessionCompleteCallback} if you want to be notified about the
     * result.
     *
     * @param arguments        FFprobe command options/arguments as string array
     * @param completeCallback callback that will be notified when execution has completed
     * @param logCallback      callback that will receive logs
     * @return FFprobe session created for this execution
     */
    public static com.antonkarpenko.ffmpegkit.FFprobeSession executeWithArgumentsAsync(final String[] arguments,
                                                           final com.antonkarpenko.ffmpegkit.FFprobeSessionCompleteCallback completeCallback,
                                                           final com.antonkarpenko.ffmpegkit.LogCallback logCallback) {
        final com.antonkarpenko.ffmpegkit.FFprobeSession session = com.antonkarpenko.ffmpegkit.FFprobeSession.create(arguments, completeCallback, logCallback);

        com.antonkarpenko.ffmpegkit.FFmpegKitConfig.asyncFFprobeExecute(session);

        return session;
    }

    /**
     * <p>Starts an asynchronous FFprobe execution with arguments provided.
     *
     * <p>Note that this method returns immediately and does not wait the execution to complete.
     * You must use an {@link com.antonkarpenko.ffmpegkit.FFprobeSessionCompleteCallback} if you want to be notified about the
     * result.
     *
     * @param arguments        FFprobe command options/arguments as string array
     * @param completeCallback callback that will be called when the execution has completed
     * @param executorService  executor service that will be used to run this asynchronous operation
     * @return FFprobe session created for this execution
     */
    public static com.antonkarpenko.ffmpegkit.FFprobeSession executeWithArgumentsAsync(final String[] arguments,
                                                           final com.antonkarpenko.ffmpegkit.FFprobeSessionCompleteCallback completeCallback,
                                                           final ExecutorService executorService) {
        final com.antonkarpenko.ffmpegkit.FFprobeSession session = com.antonkarpenko.ffmpegkit.FFprobeSession.create(arguments, completeCallback);

        com.antonkarpenko.ffmpegkit.FFmpegKitConfig.asyncFFprobeExecute(session, executorService);

        return session;
    }

    /**
     * <p>Starts an asynchronous FFprobe execution with arguments provided.
     *
     * <p>Note that this method returns immediately and does not wait the execution to complete.
     * You must use an {@link com.antonkarpenko.ffmpegkit.FFprobeSessionCompleteCallback} if you want to be notified about the
     * result.
     *
     * @param arguments        FFprobe command options/arguments as string array
     * @param completeCallback callback that will be notified when execution has completed
     * @param logCallback      callback that will receive logs
     * @param executorService  executor service that will be used to run this asynchronous operation
     * @return FFprobe session created for this execution
     */
    public static com.antonkarpenko.ffmpegkit.FFprobeSession executeWithArgumentsAsync(final String[] arguments,
                                                           final com.antonkarpenko.ffmpegkit.FFprobeSessionCompleteCallback completeCallback,
                                                           final com.antonkarpenko.ffmpegkit.LogCallback logCallback,
                                                           final ExecutorService executorService) {
        final com.antonkarpenko.ffmpegkit.FFprobeSession session = com.antonkarpenko.ffmpegkit.FFprobeSession.create(arguments, completeCallback, logCallback);

        com.antonkarpenko.ffmpegkit.FFmpegKitConfig.asyncFFprobeExecute(session, executorService);

        return session;
    }

    /**
     * <p>Synchronously executes FFprobe command provided. Space character is used to split command
     * into arguments. You can use single or double quote characters to specify arguments inside
     * your command.
     *
     * @param command FFprobe command
     * @return FFprobe session created for this execution
     */
    public static com.antonkarpenko.ffmpegkit.FFprobeSession execute(final String command) {
        return executeWithArguments(com.antonkarpenko.ffmpegkit.FFmpegKitConfig.parseArguments(command));
    }

    /**
     * <p>Starts an asynchronous FFprobe execution for the given command. Space character is used
     * to split the command into arguments. You can use single or double quote characters to
     * specify arguments inside your command.
     *
     * <p>Note that this method returns immediately and does not wait the execution to complete.
     * You must use an {@link com.antonkarpenko.ffmpegkit.FFprobeSessionCompleteCallback} if you want to be notified about the
     * result.
     *
     * @param command          FFprobe command
     * @param completeCallback callback that will be called when the execution has completed
     * @return FFprobe session created for this execution
     */
    public static com.antonkarpenko.ffmpegkit.FFprobeSession executeAsync(final String command,
                                              final com.antonkarpenko.ffmpegkit.FFprobeSessionCompleteCallback completeCallback) {
        return executeWithArgumentsAsync(com.antonkarpenko.ffmpegkit.FFmpegKitConfig.parseArguments(command), completeCallback);
    }

    /**
     * <p>Starts an asynchronous FFprobe execution for the given command. Space character is used
     * to split the command into arguments. You can use single or double quote characters to
     * specify arguments inside your command.
     *
     * <p>Note that this method returns immediately and does not wait the execution to complete.
     * You must use an {@link com.antonkarpenko.ffmpegkit.FFprobeSessionCompleteCallback} if you want to be notified about the
     * result.
     *
     * @param command          FFprobe command
     * @param completeCallback callback that will be notified when execution has completed
     * @param logCallback      callback that will receive logs
     * @return FFprobe session created for this execution
     */
    public static com.antonkarpenko.ffmpegkit.FFprobeSession executeAsync(final String command,
                                              final com.antonkarpenko.ffmpegkit.FFprobeSessionCompleteCallback completeCallback,
                                              final com.antonkarpenko.ffmpegkit.LogCallback logCallback) {
        return executeWithArgumentsAsync(com.antonkarpenko.ffmpegkit.FFmpegKitConfig.parseArguments(command), completeCallback, logCallback);
    }

    /**
     * <p>Starts an asynchronous FFprobe execution for the given command. Space character is used
     * to split the command into arguments. You can use single or double quote characters to
     * specify arguments inside your command.
     *
     * <p>Note that this method returns immediately and does not wait the execution to complete.
     * You must use an {@link com.antonkarpenko.ffmpegkit.FFprobeSessionCompleteCallback} if you want to be notified about the
     * result.
     *
     * @param command          FFprobe command
     * @param completeCallback callback that will be called when the execution has completed
     * @param executorService  executor service that will be used to run this asynchronous operation
     * @return FFprobe session created for this execution
     */
    public static com.antonkarpenko.ffmpegkit.FFprobeSession executeAsync(final String command,
                                              final com.antonkarpenko.ffmpegkit.FFprobeSessionCompleteCallback completeCallback,
                                              final ExecutorService executorService) {
        final com.antonkarpenko.ffmpegkit.FFprobeSession session = com.antonkarpenko.ffmpegkit.FFprobeSession.create(com.antonkarpenko.ffmpegkit.FFmpegKitConfig.parseArguments(command), completeCallback);

        com.antonkarpenko.ffmpegkit.FFmpegKitConfig.asyncFFprobeExecute(session, executorService);

        return session;
    }

    /**
     * <p>Starts an asynchronous FFprobe execution for the given command. Space character is used
     * to split the command into arguments. You can use single or double quote characters to
     * specify arguments inside your command.
     *
     * <p>Note that this method returns immediately and does not wait the execution to complete.
     * You must use an {@link com.antonkarpenko.ffmpegkit.FFprobeSessionCompleteCallback} if you want to be notified about the
     * result.
     *
     * @param command          FFprobe command
     * @param completeCallback callback that will be called when the execution has completed
     * @param logCallback      callback that will receive logs
     * @param executorService  executor service that will be used to run this asynchronous operation
     * @return FFprobe session created for this execution
     */
    public static com.antonkarpenko.ffmpegkit.FFprobeSession executeAsync(final String command,
                                              final com.antonkarpenko.ffmpegkit.FFprobeSessionCompleteCallback completeCallback,
                                              final com.antonkarpenko.ffmpegkit.LogCallback logCallback,
                                              final ExecutorService executorService) {
        final com.antonkarpenko.ffmpegkit.FFprobeSession session = com.antonkarpenko.ffmpegkit.FFprobeSession.create(com.antonkarpenko.ffmpegkit.FFmpegKitConfig.parseArguments(command), completeCallback, logCallback);

        com.antonkarpenko.ffmpegkit.FFmpegKitConfig.asyncFFprobeExecute(session, executorService);

        return session;
    }

    /**
     * <p>Extracts media information for the file specified with path.
     *
     * @param path path or uri of a media file
     * @return media information session created for this execution
     */
    public static com.antonkarpenko.ffmpegkit.MediaInformationSession getMediaInformation(final String path) {
        final com.antonkarpenko.ffmpegkit.MediaInformationSession session = com.antonkarpenko.ffmpegkit.MediaInformationSession.create(defaultGetMediaInformationCommandArguments(path));

        com.antonkarpenko.ffmpegkit.FFmpegKitConfig.getMediaInformationExecute(session, com.antonkarpenko.ffmpegkit.AbstractSession.DEFAULT_TIMEOUT_FOR_ASYNCHRONOUS_MESSAGES_IN_TRANSMIT);

        return session;
    }

    /**
     * <p>Extracts media information for the file specified with path.
     *
     * @param path        path or uri of a media file
     * @param waitTimeout max time to wait until media information is transmitted
     * @return media information session created for this execution
     */
    public static com.antonkarpenko.ffmpegkit.MediaInformationSession getMediaInformation(final String path,
                                                              final int waitTimeout) {
        final com.antonkarpenko.ffmpegkit.MediaInformationSession session = com.antonkarpenko.ffmpegkit.MediaInformationSession.create(defaultGetMediaInformationCommandArguments(path));

        com.antonkarpenko.ffmpegkit.FFmpegKitConfig.getMediaInformationExecute(session, waitTimeout);

        return session;
    }

    /**
     * <p>Starts an asynchronous FFprobe execution to extract the media information for the
     * specified file.
     *
     * <p>Note that this method returns immediately and does not wait the execution to complete.
     * You must use a {@link com.antonkarpenko.ffmpegkit.MediaInformationSessionCompleteCallback} if you want to be notified
     * about the result.
     *
     * @param path             path or uri of a media file
     * @param completeCallback callback that will be called when the execution has completed
     * @return media information session created for this execution
     */
    public static com.antonkarpenko.ffmpegkit.MediaInformationSession getMediaInformationAsync(final String path,
                                                                   final com.antonkarpenko.ffmpegkit.MediaInformationSessionCompleteCallback completeCallback) {
        final com.antonkarpenko.ffmpegkit.MediaInformationSession session = com.antonkarpenko.ffmpegkit.MediaInformationSession.create(defaultGetMediaInformationCommandArguments(path), completeCallback);

        com.antonkarpenko.ffmpegkit.FFmpegKitConfig.asyncGetMediaInformationExecute(session, com.antonkarpenko.ffmpegkit.AbstractSession.DEFAULT_TIMEOUT_FOR_ASYNCHRONOUS_MESSAGES_IN_TRANSMIT);

        return session;
    }

    /**
     * <p>Starts an asynchronous FFprobe execution to extract the media information for the
     * specified file.
     *
     * <p>Note that this method returns immediately and does not wait the execution to complete.
     * You must use a {@link com.antonkarpenko.ffmpegkit.MediaInformationSessionCompleteCallback} if you want to be notified
     * about the result.
     *
     * @param path             path or uri of a media file
     * @param completeCallback callback that will be notified when execution has completed
     * @param logCallback      callback that will receive logs
     * @param waitTimeout      max time to wait until media information is transmitted
     * @return media information session created for this execution
     */
    public static com.antonkarpenko.ffmpegkit.MediaInformationSession getMediaInformationAsync(final String path,
                                                                   final com.antonkarpenko.ffmpegkit.MediaInformationSessionCompleteCallback completeCallback,
                                                                   final com.antonkarpenko.ffmpegkit.LogCallback logCallback,
                                                                   final int waitTimeout) {
        final com.antonkarpenko.ffmpegkit.MediaInformationSession session = com.antonkarpenko.ffmpegkit.MediaInformationSession.create(defaultGetMediaInformationCommandArguments(path), completeCallback, logCallback);

        com.antonkarpenko.ffmpegkit.FFmpegKitConfig.asyncGetMediaInformationExecute(session, waitTimeout);

        return session;
    }

    /**
     * <p>Starts an asynchronous FFprobe execution to extract the media information for the
     * specified file.
     *
     * <p>Note that this method returns immediately and does not wait the execution to complete.
     * You must use a {@link com.antonkarpenko.ffmpegkit.MediaInformationSessionCompleteCallback} if you want to be notified
     * about the result.
     *
     * @param path             path or uri of a media file
     * @param completeCallback callback that will be called when the execution has completed
     * @param executorService  executor service that will be used to run this asynchronous operation
     * @return media information session created for this execution
     */
    public static com.antonkarpenko.ffmpegkit.MediaInformationSession getMediaInformationAsync(final String path,
                                                                   final com.antonkarpenko.ffmpegkit.MediaInformationSessionCompleteCallback completeCallback,
                                                                   final ExecutorService executorService) {
        final com.antonkarpenko.ffmpegkit.MediaInformationSession session = com.antonkarpenko.ffmpegkit.MediaInformationSession.create(defaultGetMediaInformationCommandArguments(path), completeCallback);

        com.antonkarpenko.ffmpegkit.FFmpegKitConfig.asyncGetMediaInformationExecute(session, executorService, com.antonkarpenko.ffmpegkit.AbstractSession.DEFAULT_TIMEOUT_FOR_ASYNCHRONOUS_MESSAGES_IN_TRANSMIT);

        return session;
    }

    /**
     * <p>Starts an asynchronous FFprobe execution to extract the media information for the
     * specified file.
     *
     * <p>Note that this method returns immediately and does not wait the execution to complete.
     * You must use a {@link com.antonkarpenko.ffmpegkit.MediaInformationSessionCompleteCallback} if you want to be notified
     * about the result.
     *
     * @param path             path or uri of a media file
     * @param completeCallback callback that will be notified when execution has completed
     * @param logCallback      callback that will receive logs
     * @param executorService  executor service that will be used to run this asynchronous operation
     * @param waitTimeout      max time to wait until media information is transmitted
     * @return media information session created for this execution
     */
    public static com.antonkarpenko.ffmpegkit.MediaInformationSession getMediaInformationAsync(final String path,
                                                                   final com.antonkarpenko.ffmpegkit.MediaInformationSessionCompleteCallback completeCallback,
                                                                   final com.antonkarpenko.ffmpegkit.LogCallback logCallback,
                                                                   final ExecutorService executorService,
                                                                   final int waitTimeout) {
        final com.antonkarpenko.ffmpegkit.MediaInformationSession session = com.antonkarpenko.ffmpegkit.MediaInformationSession.create(defaultGetMediaInformationCommandArguments(path), completeCallback, logCallback);

        com.antonkarpenko.ffmpegkit.FFmpegKitConfig.asyncGetMediaInformationExecute(session, executorService, waitTimeout);

        return session;
    }

    /**
     * <p>Extracts media information using the command provided.
     *
     * @param command FFprobe command that prints media information for a file in JSON format
     * @return media information session created for this execution
     */
    public static com.antonkarpenko.ffmpegkit.MediaInformationSession getMediaInformationFromCommand(final String command) {
        final com.antonkarpenko.ffmpegkit.MediaInformationSession session = com.antonkarpenko.ffmpegkit.MediaInformationSession.create(com.antonkarpenko.ffmpegkit.FFmpegKitConfig.parseArguments(command));

        com.antonkarpenko.ffmpegkit.FFmpegKitConfig.getMediaInformationExecute(session, com.antonkarpenko.ffmpegkit.AbstractSession.DEFAULT_TIMEOUT_FOR_ASYNCHRONOUS_MESSAGES_IN_TRANSMIT);

        return session;
    }

    /**
     * <p>Starts an asynchronous FFprobe execution to extract media information using a command.
     * The command passed to this method must generate the output in JSON format in order to
     * successfully extract media information from it.
     *
     * <p>Note that this method returns immediately and does not wait the execution to complete.
     * You must use a {@link com.antonkarpenko.ffmpegkit.MediaInformationSessionCompleteCallback} if you want to be notified
     * about the result.
     *
     * @param command          FFprobe command that prints media information for a file in JSON
     *                         format
     * @param completeCallback callback that will be notified when execution has completed
     * @param logCallback      callback that will receive logs
     * @param waitTimeout      max time to wait until media information is transmitted
     * @return media information session created for this execution
     */
    public static com.antonkarpenko.ffmpegkit.MediaInformationSession getMediaInformationFromCommandAsync(final String command,
                                                                              final com.antonkarpenko.ffmpegkit.MediaInformationSessionCompleteCallback completeCallback,
                                                                              final com.antonkarpenko.ffmpegkit.LogCallback logCallback,
                                                                              final int waitTimeout) {
        return getMediaInformationFromCommandArgumentsAsync(com.antonkarpenko.ffmpegkit.FFmpegKitConfig.parseArguments(command), completeCallback, logCallback, waitTimeout);
    }

    /**
     * <p>Starts an asynchronous FFprobe execution to extract media information using command
     * arguments. The command passed to this method must generate the output in JSON format in
     * order to successfully extract media information from it.
     *
     * <p>Note that this method returns immediately and does not wait the execution to complete.
     * You must use a {@link com.antonkarpenko.ffmpegkit.MediaInformationSessionCompleteCallback} if you want to be notified
     * about the result.
     *
     * @param arguments        FFprobe command arguments that print media information for a file in
     *                         JSON format
     * @param completeCallback callback that will be notified when execution has completed
     * @param logCallback      callback that will receive logs
     * @param waitTimeout      max time to wait until media information is transmitted
     * @return media information session created for this execution
     */
    private static com.antonkarpenko.ffmpegkit.MediaInformationSession getMediaInformationFromCommandArgumentsAsync(final String[] arguments,
                                                                                        final com.antonkarpenko.ffmpegkit.MediaInformationSessionCompleteCallback completeCallback,
                                                                                        final com.antonkarpenko.ffmpegkit.LogCallback logCallback,
                                                                                        final int waitTimeout) {
        final com.antonkarpenko.ffmpegkit.MediaInformationSession session = com.antonkarpenko.ffmpegkit.MediaInformationSession.create(arguments, completeCallback, logCallback);

        com.antonkarpenko.ffmpegkit.FFmpegKitConfig.asyncGetMediaInformationExecute(session, waitTimeout);

        return session;
    }

    /**
     * <p>Lists all FFprobe sessions in the session history.
     *
     * @return all FFprobe sessions in the session history
     */
    public static List<com.antonkarpenko.ffmpegkit.FFprobeSession> listFFprobeSessions() {
        return com.antonkarpenko.ffmpegkit.FFmpegKitConfig.getFFprobeSessions();
    }

    /**
     * <p>Lists all MediaInformation sessions in the session history.
     *
     * @return all MediaInformation sessions in the session history
     */
    public static List<com.antonkarpenko.ffmpegkit.MediaInformationSession> listMediaInformationSessions() {
        return com.antonkarpenko.ffmpegkit.FFmpegKitConfig.getMediaInformationSessions();
    }

}
