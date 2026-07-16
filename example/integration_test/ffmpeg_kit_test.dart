import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_https_gpl/ffmpeg_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:ffmpeg_kit_flutter_new_https_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new_https_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_https_gpl/return_code.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('reports FFmpeg version and platform', (tester) async {
    final version = await FFmpegKitConfig.getFFmpegVersion();
    final platform = await FFmpegKitConfig.getPlatform();
    debugPrint('FFmpeg version: $version, platform: $platform');
    expect(version, isNotNull);
    // ffmpeg-kit reports the upstream tag name, e.g. "n8.1.2"
    expect(version, contains('8.1'));
  });

  testWidgets('encodes video with libx264 (GPL build)', (tester) async {
    final tmp = await getTemporaryDirectory();
    // On sandboxed macOS the temp directory may not exist yet.
    Directory(tmp.path).createSync(recursive: true);
    final out = '${tmp.path}/spm_test.mp4';
    final file = File(out);
    if (file.existsSync()) file.deleteSync();

    final session = await FFmpegKit.execute(
        '-y -f lavfi -i testsrc=duration=1:size=320x240:rate=10 '
        '-c:v libx264 -pix_fmt yuv420p $out');
    final rc = await session.getReturnCode();
    final logs = await session.getAllLogsAsString();
    expect(ReturnCode.isSuccess(rc), isTrue,
        reason: 'ffmpeg failed (rc=$rc): $logs');
    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), greaterThan(1000));
  });

  testWidgets('ffprobe reads the encoded file', (tester) async {
    final tmp = await getTemporaryDirectory();
    final out = '${tmp.path}/spm_test.mp4';
    final session = await FFprobeKit.getMediaInformation(out);
    final info = session.getMediaInformation();
    expect(info, isNotNull);
    final streams = info!.getStreams();
    expect(streams, isNotEmpty);
    expect(streams.first.getCodec(), 'h264');
  });
}
