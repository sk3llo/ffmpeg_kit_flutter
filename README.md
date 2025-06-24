
# FFmpegKit for Flutter [![pub](https://img.shields.io/badge/pub-2.0.0-blue)](https://pub.dev/packages/ffmpeg_kit_flutter_new) [![discord](https://img.shields.io/badge/discord-purple)](https://discord.gg/s2HCWep9)

## Upgraded version of the original [Flutter FFmpegKit](https://github.com/arthenica/ffmpeg-kit/tree/main/flutter/flutter).

### 1. Features

- Updated Android and MacOS bindings to work with Flutter 3.29
- Includes both `FFmpeg` and `FFprobe`
- Supports
    - `Android`, `iOS` and `macOS`
- FFmpeg `v6.0.2-LTS`
- `arm-v7a`, `arm-v7a-neon`, `arm64-v8a`, `x86` and `x86_64` architectures on Android
    - `Android API Level 24` or later
    - `armv7`, `armv7s`, `arm64`, `arm64-simulator`, `i386`, `x86_64`, `x86_64-mac-catalyst` and `arm64-mac-catalyst`  
      architectures on iOS
    - `iOS SDK 14.0` or later
    - `arm64` and `x86_64` architectures on macOS
    - `macOS SDK 10.15` or later
- Can process Storage Access Framework (SAF) Uris on Android
- 25 external libraries

  `dav1d`, `fontconfig`, `freetype`, `fribidi`, `gmp`, `gnutls`, `kvazaar`, `lame`, `libass`, `libiconv`, `libilbc`  
  , `libtheora`, `libvorbis`, `libvpx`, `libwebp`, `libxml2`, `opencore-amr`, `opus`, `shine`, `snappy`, `soxr`  
  , `speex`, `twolame`, `vo-amrwbenc`, `zimg`

- 4 external libraries with GPL license

  `vid.stab`, `x264`, `x265`, `xvidcore`

- Licensed under `LGPL 3.0` by default, some packages licensed by `GPL v3.0` effectively

### 2. Known issues

#### Android:
```
...
Running Gradle task 'assembleDebug'...
*** DOWNLOADING AAR ***
...android/src/main/java/com/arthenica/ffmpegkit/flutter FFmpegSessionExecuteTask.java:5: error: cannot find symbol
import com.arthenica.ffmpegkit.FFmpegKitConfig;
...100 more lines...
```
The error above is going to happen during the first run only ONCE. It occurs because downloaded `.aar` cannot be found after Gradle assemble task. Sadly, mentioned `.aar` cannot be bundled along with the package [because of the pub.dev package restrictions](https://dart.dev/tools/pub/publishing#prepare-your-package-for-publication) and always have to be downloaded first.

### 3. Installation

Add `ffmpeg_kit_flutter_new` as a dependency in your `pubspec.yaml file`.

```yaml
dependencies:  
 ffmpeg_kit_flutter_new: ^2.0.0
```

NOTE: Android know issue:

#### 4. Platform Support

The following table shows Android API level, iOS deployment target and macOS deployment target requirements in  
`ffmpeg_kit_flutter_new` releases.

<table align="center">  
  <thead>  
    <tr>  
      <th align="center" colspan="3">LTS Release</th>  
    </tr>  
    <tr>  
      <th align="center">Android<br>API Level</th>  
      <th align="center">iOS Minimum<br>Deployment Target</th>  
      <th align="center">macOS Minimum<br>Deployment Target</th>  
    </tr>  
  </thead>  
  <tbody>  
    <tr>  
      <td align="center">24</td>  
      <td align="center">14</td>  
      <td align="center">10.15</td>  
    </tr>  
  </tbody>  
</table>  

### 4. Using

1. Execute FFmpeg commands.

```dart  
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';

FFmpegKit.execute('-i file1.mp4 -c:v mpeg4 file2.mp4').then((session) async {
    final returnCode = await session.getReturnCode();  
    if (ReturnCode.isSuccess(returnCode)) {  
    // SUCCESS  
    } else if (ReturnCode.isCancel(returnCode)) {  
    // CANCEL  
    } else {  
    // ERROR  
    }
});
```  
2. Each `execute` call creates a new session. Access every detail about your execution from the session created.  
  
```dart  
FFmpegKit.execute('-i file1.mp4 -c:v mpeg4 file2.mp4').then((session) async {  
    // Unique session id created for this execution
    final sessionId = session.getSessionId();  
    // Command arguments as a single string
    final command = session.getCommand();  
    // Command arguments
    final commandArguments = session.getArguments();  
    // State of the execution. Shows whether it is still running or completed
    final state = await session.getState();  
    // Return code for completed sessions. Will be undefined if session is still running or FFmpegKit fails to run it
    final returnCode = await session.getReturnCode();  
    final startTime = session.getStartTime();
    final endTime = await session.getEndTime();
    final duration = await session.getDuration();  
    // Console output generated for this execution
    final output = await session.getOutput();  
    // The stack trace if FFmpegKit fails to run a command
    final failStackTrace = await session.getFailStackTrace();  
    // The list of logs generated for this execution
    final logs = await session.getLogs();  
    // The list of statistics generated for this execution (only available on FFmpegSession)
    final statistics = await (session as FFmpegSession).getStatistics();  
});
```  
3. Execute `FFmpeg` commands by providing session specific `execute`/`log`/`session` callbacks.

```dart  
FFmpegKit.executeAsync('-i file1.mp4 -c:v mpeg4 file2.mp4', (Session session) async {
    // CALLED WHEN SESSION IS EXECUTED  
}, (Log log) {  
    // CALLED WHEN SESSION PRINTS LOGS  
}, (Statistics statistics) {  
    // CALLED WHEN SESSION GENERATES STATISTICS  
});
```  
4. Execute `FFprobe` commands.  
  
```dart  
FFprobeKit.execute(ffprobeCommand).then((session) async {  
    // CALLED WHEN SESSION IS EXECUTED  
});  
```  
5. Get media information for a file/url.

```dart  
FFprobeKit.getMediaInformation('<file path or url>').then((session) async {  
    final information = await session.getMediaInformation();  
    if (information == null) {  
        // CHECK THE FOLLOWING ATTRIBUTES ON ERROR
        final state = FFmpegKitConfig.sessionStateToString(await session.getState());
        final returnCode = await session.getReturnCode();
        final failStackTrace = await session.getFailStackTrace();
        final duration = await session.getDuration();
        final output = await session.getOutput();
    }
});
```  
6. Stop ongoing FFmpeg operations.  
  
- Stop all sessions  
```dart  
FFmpegKit.cancel();
```
- Stop a specific session  
```dart  
FFmpegKit.cancel(sessionId);  
```  
7. (Android) Convert Storage Access Framework (SAF) Uris into paths that can be read or written by  
   `FFmpegKit` and `FFprobeKit`.

- Reading a file:
```dart  
FFmpegKitConfig.selectDocumentForRead('*/*').then((uri) {  
    FFmpegKitConfig.getSafParameterForRead(uri!).then((safUrl) {
        FFmpegKit.executeAsync("-i ${safUrl!} -c:v mpeg4 file2.mp4");
    });
});
```  
- Writing to a file:  
```dart  
FFmpegKitConfig.selectDocumentForWrite('video.mp4', 'video/*').then((uri) {
    FFmpegKitConfig.getSafParameterForWrite(uri!).then((safUrl) {
        FFmpegKit.executeAsync("-i file1.mp4 -c:v mpeg4 ${safUrl}");
    });
});  
```  
8. Get previous `FFmpeg`, `FFprobe` and `MediaInformation` sessions from the session history.

```dart  
FFmpegKit.listSessions().then((sessionList) {  
    sessionList.forEach((session) {
        final sessionId = session.getSessionId();
    });
});  
FFprobeKit.listFFprobeSessions().then((sessionList) {
    sessionList.forEach((session) {
        final sessionId = session.getSessionId();
    });
});  
FFprobeKit.listMediaInformationSessions().then((sessionList) {
    sessionList.forEach((session) {
        final sessionId = session.getSessionId();
    });
});
```  
9. Enable global callbacks.  
  
- Session type specific Complete Callbacks, called when an async session has been completed  
  
```dart  
FFmpegKitConfig.enableFFmpegSessionCompleteCallback((session) {
    final sessionId = session.getSessionId();
});  
FFmpegKitConfig.enableFFprobeSessionCompleteCallback((session) {
    final sessionId = session.getSessionId();
});  
FFmpegKitConfig.enableMediaInformationSessionCompleteCallback((session) {
    final sessionId = session.getSessionId();
});  
```  
- Log Callback, called when a session generates logs

```dart  
FFmpegKitConfig.enableLogCallback((log) {  
    final message = log.getMessage();
});
```  
- Statistics Callback, called when a session generates statistics  
  
```dart  
FFmpegKitConfig.enableStatisticsCallback((statistics) {  
    final size = statistics.getSize();
});  
```  
10. Register system fonts and custom font directories.

```dart  
FFmpegKitConfig.setFontDirectoryList(["/system/fonts", "/System/Library/Fonts", "<folder with fonts>"]);
```
