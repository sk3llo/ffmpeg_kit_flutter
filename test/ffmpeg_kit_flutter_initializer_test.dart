import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new_min/level.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Fails the way dart:io's stdout does in a Windows GUI app with no stdout
// handle: write() returns normally and the error arrives later on done.
class _HandlelessStdout extends Fake implements Stdout {
  final Completer<void> _done = Completer<void>();
  int writes = 0;

  @override
  Future<void> get done => _done.future;

  @override
  void write(Object? object) {
    writes++;
    scheduleMicrotask(() {
      if (!_done.isCompleted) {
        _done.completeError(const FileSystemException(
            'writeFrom failed', '', OSError('The handle is invalid', 6)));
      }
    });
  }
}

Map<String, Object> _logEvent(String message) => {
      'FFmpegKitLogCallbackEvent': {
        'sessionId': 1,
        'level': Level.avLogInfo,
        'message': message,
      },
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('printing logs to a stdout that fails raises no uncaught error',
      () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        const MethodChannel('flutter.arthenica.com/ffmpeg_kit'),
        (call) async => const {
              'getArch': 'test',
              'getPackageName': 'test',
              'getPlatform': 'test',
            }[call.method]);
    late MockStreamHandlerEventSink events;
    messenger.setMockStreamHandler(
        const EventChannel('flutter.arthenica.com/ffmpeg_kit_event'),
        MockStreamHandler.inline(onListen: (_, sink) => events = sink));

    final handleless = _HandlelessStdout();
    await IOOverrides.runZoned(() async {
      await FFmpegKitConfig.init();
      events.success(_logEvent('first line\n'));
      await Future<void>.delayed(Duration.zero);
      events.success(_logEvent('second line\n'));
      await Future<void>.delayed(Duration.zero);
    }, stdout: () => handleless);

    expect(handleless.writes, 1);
  });
}
