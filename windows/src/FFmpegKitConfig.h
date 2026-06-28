/*
 * Copyright (c) 2022 Taner Sener
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

#ifndef FFMPEG_KIT_CONFIG_H
#define FFMPEG_KIT_CONFIG_H

#include <stdio.h>
#include <thread>
#include "FFmpegSession.h"
#include "FFprobeSession.h"
#include "Level.h"
#include "LogCallback.h"
#include "MediaInformationSession.h"
#include "FFmpegKitSignal.h"
#include "StatisticsCallback.h"
#include <map>

namespace ffmpegkit {

    class FFmpegKitConfig {
        public:

            static constexpr const char* FFmpegKitVersion = "6.0";

            static constexpr const char* FFmpegKitNamedPipePrefix = "fk_pipe_";

            static void enableRedirection();

            static void disableRedirection();

            static int setFontconfigConfigurationPath(const std::string& path);

            static void setFontDirectory(const std::string& fontDirectoryPath, const std::map<std::string,std::string>& fontNameMapping);

            static void setFontDirectoryList(const std::list<std::string>& fontDirectoryList, const std::map<std::string,std::string>& fontNameMapping);

            static std::shared_ptr<std::string> registerNewFFmpegPipe();

            static void closeFFmpegPipe(const std::string& ffmpegPipePath);

            static std::string getFFmpegVersion();

            static std::string getVersion();

            static bool isLTSBuild();

            static std::string getBuildDate();

            static int setEnvironmentVariable(const std::string& variableName, const std::string& variableValue);

            static void ignoreSignal(const ffmpegkit::Signal signal);

            static void ffmpegExecute(const std::shared_ptr<ffmpegkit::FFmpegSession> ffmpegSession);

            static void ffprobeExecute(const std::shared_ptr<ffmpegkit::FFprobeSession> ffprobeSession);

            static void getMediaInformationExecute(const std::shared_ptr<ffmpegkit::MediaInformationSession> mediaInformationSession, const int waitTimeout);

            static void asyncFFmpegExecute(const std::shared_ptr<ffmpegkit::FFmpegSession> ffmpegSession);

            static void asyncFFprobeExecute(const std::shared_ptr<ffmpegkit::FFprobeSession> ffprobeSession);

            static void asyncGetMediaInformationExecute(const std::shared_ptr<ffmpegkit::MediaInformationSession> mediaInformationSession, int waitTimeout);

            static void enableLogCallback(const ffmpegkit::LogCallback logCallback);

            static void enableStatisticsCallback(const ffmpegkit::StatisticsCallback statisticsCallback);

            static void enableFFmpegSessionCompleteCallback(const FFmpegSessionCompleteCallback ffmpegSessionCompleteCallback);

            static FFmpegSessionCompleteCallback getFFmpegSessionCompleteCallback();

            static void enableFFprobeSessionCompleteCallback(const FFprobeSessionCompleteCallback ffprobeSessionCompleteCallback);

            static FFprobeSessionCompleteCallback getFFprobeSessionCompleteCallback();

            static void enableMediaInformationSessionCompleteCallback(const MediaInformationSessionCompleteCallback mediaInformationSessionCompleteCallback);

            static MediaInformationSessionCompleteCallback getMediaInformationSessionCompleteCallback();

            static ffmpegkit::Level getLogLevel();

            static void setLogLevel(const ffmpegkit::Level level);

            static std::string logLevelToString(const ffmpegkit::Level level);

            static int getSessionHistorySize();

            static void setSessionHistorySize(const int sessionHistorySize);

            static std::shared_ptr<ffmpegkit::Session> getSession(const long sessionId);

            static std::shared_ptr<ffmpegkit::Session> getLastSession();

            static std::shared_ptr<ffmpegkit::Session> getLastCompletedSession();

            static std::shared_ptr<std::list<std::shared_ptr<ffmpegkit::Session>>> getSessions();

            static void clearSessions();

            static std::shared_ptr<std::list<std::shared_ptr<ffmpegkit::FFmpegSession>>> getFFmpegSessions();

            static std::shared_ptr<std::list<std::shared_ptr<ffmpegkit::FFprobeSession>>> getFFprobeSessions();

            static std::shared_ptr<std::list<std::shared_ptr<ffmpegkit::MediaInformationSession>>> getMediaInformationSessions();

            static std::shared_ptr<std::list<std::shared_ptr<ffmpegkit::Session>>> getSessionsByState(const SessionState state);

            static LogRedirectionStrategy getLogRedirectionStrategy();

            static void setLogRedirectionStrategy(const LogRedirectionStrategy logRedirectionStrategy);

            static int messagesInTransmit(const long sessionId);

            /**
             * Blocks the calling thread for up to the given number of milliseconds, or until an
             * asynchronous callback message is consumed (whichever comes first). Used to wait
             * efficiently for in-transit messages instead of busy polling.
             *
             * @param milliseconds maximum time to wait in milliseconds
             */
            static void waitForMessagesInTransmit(const int milliseconds);

            static std::string sessionStateToString(SessionState state);

            static std::list<std::string> parseArguments(const std::string& command);

            static std::string argumentsToString(std::shared_ptr<std::list<std::string>> arguments);

    };

}

#endif // FFMPEG_KIT_CONFIG_H
