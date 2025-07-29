import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_video/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_video/log.dart';
import 'package:ffmpeg_kit_flutter_new_video/session.dart';
import 'package:ffmpeg_kit_flutter_new_video/statistics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FFmpeg Kit Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'FFmpeg Kit Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String logString = 'FFmpeg Kit Example\n\n';
  bool isProcessing = false;
  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(24),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Logs:',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      logString,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isProcessing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: LinearProgressIndicator(),
            ),
          BottomAppBar(
            child: SizedBox(
              height: 40,
              child: ListView(
                padding: const EdgeInsets.all(2),
                scrollDirection: Axis.horizontal,
                children: [
                  ElevatedButton(
                    onPressed:
                        isProcessing
                            ? null
                            : () => executeFFmpegCommand('list_codecs'),
                    child: const Text('List Codecs'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed:
                        isProcessing
                            ? null
                            : () => executeFFmpegCommand('mediacodec'),
                    child: const Text('MediaCodec'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed:
                        isProcessing
                            ? null
                            : () => executeFFmpegCommand('kvazaar'),
                    child: const Text('kvazaar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed:
                        isProcessing
                            ? null
                            : () => executeFFmpegCommand('libtheora'),
                    child: const Text('libtheora'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed:
                        isProcessing
                            ? null
                            : () => executeFFmpegCommand('libvpx'),
                    child: const Text('libvpx'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed:
                        isProcessing
                            ? null
                            : () => executeFFmpegCommand('libwebp'),
                    child: const Text('libwebp'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed:
                        isProcessing
                            ? null
                            : () => executeFFmpegCommand('snappy'),
                    child: const Text('snappy'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed:
                        isProcessing
                            ? null
                            : () => executeFFmpegCommand('zimg'),
                    child: const Text('zimg'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<File> _copyAssetToTemp(String assetName) async {
    final tempDir = await getTemporaryDirectory();
    final assetData = await rootBundle.load('assets/$assetName');
    final tempFile = File('${tempDir.path}/$assetName');
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
    await tempFile.writeAsBytes(assetData.buffer.asUint8List());
    return tempFile;
  }

  void executeFFmpegCommand(String mode) async {
    setState(() {
      isProcessing = true;
      logString = 'Starting FFmpeg processing...\n\n';
    });

    try {
      String command = '';
      String description = '';
      File inputFile;
      File outputFile;

      final tempDir = await getTemporaryDirectory();

      inputFile = await _copyAssetToTemp('sample_video.mp4');

      switch (mode) {
        case 'list_codecs':
          if (Platform.isAndroid) {
            command = '-hide_banner -encoders | grep -i mediacodec';
            description = 'List MediaCodec codecs';
          } else if (Platform.isIOS || Platform.isMacOS) {
            command = '-hide_banner -encoders | grep -i videotoolbox';
            description = 'List VideoToolbox codecs';
          } else {
            command = '-hide_banner -encoders';
            description = 'List all codecs';
          }
          break;
        case 'mediacodec':
          command = '-hide_banner -encoders | grep -i mediacodec';
          description = 'List MediaCodec codecs';
          break;
        case 'kvazaar':
          outputFile = File('${tempDir.path}/output_kvazaar.mp4');
          command =
              '-y -i ${inputFile.path} -c:v libkvazaar -preset ultrafast ${outputFile.path}';
          description = 'Encode HEVC with kvazaar';
          break;
        case 'libtheora':
          outputFile = File('${tempDir.path}/output.ogv');
          command =
              '-y -i ${inputFile.path} -c:v libtheora -q:v 7 ${outputFile.path}';
          description = 'Encode with libtheora';
          break;
        case 'libvpx':
          outputFile = File('${tempDir.path}/output.webm');
          command =
              '-y -i ${inputFile.path} -c:v libvpx-vp9 -b:v 1M -c:a libopus ${outputFile.path}';
          description = 'Encode VP9 with libvpx';
          break;
        case 'libwebp':
          outputFile = File('${tempDir.path}/output.webp');
          command =
              '-y -i ${inputFile.path} -c:v libwebp -loop 0 -an -vsync 0 ${outputFile.path}';
          description = 'Encode to animated WebP';
          break;
        case 'snappy':
          outputFile = File('${tempDir.path}/output_hap.mov');
          command =
              '-y -i ${inputFile.path} -c:v hap -format hap_q ${outputFile.path}';
          description = 'Encode with HAP (uses snappy)';
          break;
        case 'zimg':
          outputFile = File('${tempDir.path}/output_zscale.mp4');
          command =
              '-y -i ${inputFile.path} -vf "zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709" ${outputFile.path}';
          description = 'Apply filter with zimg (zscale)';
          break;
        default:
          outputFile = File('${tempDir.path}/output_default.mp4');
          command =
              '-y -i ${inputFile.path} -c:v mpeg4 -preset ultrafast ${outputFile.path}';
          description = 'Default video encoding';
      }

      setState(() {
        logString += 'Mode: $description\n';
        logString += 'Command: $command\n\n';
        logString += 'Processing...\n';
      });

      /// Execute FFmpeg command
      await FFmpegKit.executeAsync(
        command,
        (Session session) async {
          final output = await session.getOutput();
          final returnCode = await session.getReturnCode();
          final duration = await session.getDuration();

          setState(() {
            logString += '\n✅ Processing completed!\n';
            logString += 'Return code: $returnCode\n';
            logString += 'Duration: ${duration}ms\n';
            if (output != null && output.isNotEmpty) {
              logString += 'Output: $output\n';
            }
            isProcessing = false;
          });

          debugPrint('session: $output');
        },
        (Log log) {
          setState(() {
            logString += log.getMessage();
          });
          debugPrint('log: ${log.getMessage()}');
        },
        (Statistics statistics) {
          debugPrint('statistics: ${statistics.getTime()}');
        },
      );
    } catch (e) {
      setState(() {
        logString += '\n❌ Error: $e\n';
        isProcessing = false;
      });
    }
  }
}
