import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/log.dart';
import 'package:ffmpeg_kit_flutter_new_min/session.dart';
import 'package:ffmpeg_kit_flutter_new_min/statistics.dart';
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
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            ElevatedButton(
              onPressed:
                  isProcessing
                      ? null
                      : () => executeFFmpegCommand('list_codecs'),
              child: const Text('List Codecs'),
            ),
            ElevatedButton(
              onPressed:
                  isProcessing
                      ? null
                      : () => executeFFmpegCommand('mediacodec'),
              child: const Text('MediaCodec'),
            ),
          ],
        ),
      ),
    );
  }

  void executeFFmpegCommand(String mode) async {
    setState(() {
      isProcessing = true;
      logString = 'Starting FFmpeg processing...\n\n';
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final sampleVideoRoot = await rootBundle.load('assets/sample_video.mp4');
      final sampleVideoFile = File('${tempDir.path}/sample_video.mp4');
      final outputFile = File('${tempDir.path}/output.mp4');

      await sampleVideoFile.writeAsBytes(sampleVideoRoot.buffer.asUint8List());
      if (outputFile.existsSync()) await outputFile.delete();

      String command;
      String description;

      switch (mode) {
        case 'videotoolbox':
          command =
              '-i ${sampleVideoFile.path} -c:v h264_videotoolbox -b:v 2M ${outputFile.path}';
          description = 'Hardware encoding (VideoToolbox)';
          break;
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
        default:
          command =
              '-i ${sampleVideoFile.path} -c:v mpeg4 -preset ultrafast ${outputFile.path}';
          description = 'Default encoding';
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
            logString += 'Output: $output\n';
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
          setState(() {
            logString +=
                '\n📊 Progress: ${statistics.getSize()} bytes, ${statistics.getTime()}ms\n';
          });
          debugPrint('statistics: ${statistics.getSize()}');
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
