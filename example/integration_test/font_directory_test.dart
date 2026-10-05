import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_full/ffmpeg_kit_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Regression tests for #167: on iOS and macOS, calling setFontDirectory or
// setFontDirectoryList without the optional font name map aborted the app with
// -[NSNull allKeys].
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final apple = Platform.isIOS || Platform.isMacOS;

  // The native layer writes NSTemporaryDirectory()/fontconfig/fonts.conf.
  final conf = File('${Directory.systemTemp.path}/fontconfig/fonts.conf');

  Directory fontDirectory() {
    final dir = Directory.systemTemp.createTempSync('fonts_');
    addTearDown(() => dir.deleteSync(recursive: true));
    return dir;
  }

  // Runs [register] and returns the fonts.conf it wrote.
  Future<String> configure(Future<void> Function() register) async {
    if (conf.existsSync()) conf.deleteSync();
    await register();
    expect(conf.existsSync(), isTrue, reason: 'fonts.conf was not written');
    return conf.readAsStringSync();
  }

  int mappingCount(String text) =>
      '<match target="pattern">'.allMatches(text).length;

  testWidgets('setFontDirectory with no font name map', (tester) async {
    final dir = fontDirectory();
    final text = await configure(
      () => FFmpegKitConfig.setFontDirectory(dir.path),
    );
    expect(text, contains('<dir>${dir.path}</dir>'), reason: text);
    expect(mappingCount(text), 0, reason: text);
  }, skip: !apple);

  testWidgets('setFontDirectoryList with no font name map', (tester) async {
    final first = fontDirectory();
    final second = fontDirectory();
    final text = await configure(
      () => FFmpegKitConfig.setFontDirectoryList([first.path, second.path]),
    );
    expect(text, contains('<dir>${first.path}</dir>'), reason: text);
    expect(text, contains('<dir>${second.path}</dir>'), reason: text);
    expect(mappingCount(text), 0, reason: text);
  }, skip: !apple);

  testWidgets('setFontDirectory with a font name map', (tester) async {
    final dir = fontDirectory();
    final text = await configure(
      () => FFmpegKitConfig.setFontDirectory(dir.path, {
        'FontAlias': 'Helvetica',
      }),
    );
    expect(text, contains('<dir>${dir.path}</dir>'), reason: text);
    expect(mappingCount(text), 1, reason: text);
    expect(text, contains('<string>FontAlias</string>'), reason: text);
    expect(text, contains('<string>Helvetica</string>'), reason: text);
  }, skip: !apple);

  testWidgets('setFontDirectoryList with a font name map', (tester) async {
    final first = fontDirectory();
    final second = fontDirectory();
    final text = await configure(
      () => FFmpegKitConfig.setFontDirectoryList(
        [first.path, second.path],
        {'FontAlias': 'Courier'},
      ),
    );
    expect(text, contains('<dir>${first.path}</dir>'), reason: text);
    expect(text, contains('<dir>${second.path}</dir>'), reason: text);
    expect(mappingCount(text), 1, reason: text);
    expect(text, contains('<string>FontAlias</string>'), reason: text);
    expect(text, contains('<string>Courier</string>'), reason: text);
  }, skip: !apple);

  testWidgets('no font name map writes the same fonts.conf as an empty one', (
    tester,
  ) async {
    final dir = fontDirectory();
    final withoutMap = await configure(
      () => FFmpegKitConfig.setFontDirectory(dir.path),
    );
    final withEmptyMap = await configure(
      () => FFmpegKitConfig.setFontDirectory(dir.path, {}),
    );
    expect(withoutMap, withEmptyMap);
  }, skip: !apple);
}
