import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/log.dart';
import 'package:ffmpeg_kit_flutter_new_audio/session.dart';
import 'package:ffmpeg_kit_flutter_new_audio/statistics.dart';
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
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
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
  final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(24));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.inversePrimary, title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Text('Logs:', style: Theme.of(context).textTheme.headlineSmall)),
                    const SizedBox(height: 16),
                    Text(logString, style: const TextStyle(fontSize: 14, fontFamily: 'monospace')),
                  ],
                ),
              ),
            ),
          ),
          if (isProcessing) const Padding(padding: EdgeInsets.all(16.0), child: LinearProgressIndicator()),
          BottomAppBar(
            // padding: EdgeInsets.zero,
            child: SizedBox(
              height: 40,
              child: ListView(
                padding: const EdgeInsets.all(2),
                scrollDirection: Axis.horizontal,
                children: [
                  ElevatedButton(
                    onPressed: isProcessing ? null : () => executeFFmpegCommand('list_codecs'),
                    child: const Text('List Codecs'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isProcessing ? null : () => executeFFmpegCommand('mediacodec'),
                    child: const Text('MediaCodec'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isProcessing ? null : () => executeFFmpegCommand('lame'),
                    child: const Text('LAME'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isProcessing ? null : () => executeFFmpegCommand('libilbc'),
                    child: const Text('iLBC'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isProcessing ? null : () => executeFFmpegCommand('libvorbis'),
                    child: const Text('Vorbis'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isProcessing ? null : () => executeFFmpegCommand('opencore-amr'),
                    child: const Text('AMR'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isProcessing ? null : () => executeFFmpegCommand('opus'),
                    child: const Text('Opus'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isProcessing ? null : () => executeFFmpegCommand('shine'),
                    child: const Text('Shine'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isProcessing ? null : () => executeFFmpegCommand('soxr'),
                    child: const Text('SoXr'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isProcessing ? null : () => executeFFmpegCommand('speex'),
                    child: const Text('Speex'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isProcessing ? null : () => executeFFmpegCommand('twolame'),
                    child: const Text('TwoLAME'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isProcessing ? null : () => executeFFmpegCommand('vo-amrwbenc'),
                    child: const Text('AMR-WB'),
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

      // Determine if the command is for audio or video
      final audioModes = [
        'lame',
        'libilbc',
        'libvorbis',
        'opencore-amr',
        'opus',
        'shine',
        'soxr',
        'speex',
        'twolame',
        'vo-amrwbenc',
      ];

      if (audioModes.contains(mode)) {
        inputFile = await _copyAssetToTemp('sample_audio.wav');
      } else {
        inputFile = await _copyAssetToTemp('sample_video.mp4');
      }

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
        // Audio Library Test Cases
        case 'lame':
          outputFile = File('${tempDir.path}/output.mp3');
          command = '-y -i ${inputFile.path} -c:a libmp3lame -q:a 2 ${outputFile.path}';
          description = 'Encode with LAME (MP3)';
          break;
        case 'libilbc':
          outputFile = File('${tempDir.path}/output.lbc');
          command = '-y -i ${inputFile.path} -c:a libilbc -ar 8000 -b:a 15.2k ${outputFile.path}';
          description = 'Encode with iLBC';
          break;
        case 'libvorbis':
          outputFile = File('${tempDir.path}/output.ogg');
          command = '-y -i ${inputFile.path} -c:a libvorbis -qscale:a 5 ${outputFile.path}';
          description = 'Encode with Vorbis';
          break;
        case 'opencore-amr':
          outputFile = File('${tempDir.path}/output.amr');
          command = '-y -i ${inputFile.path} -c:a libopencore_amrnb -ar 8000 -b:a 12.2k ${outputFile.path}';
          description = 'Encode with OpenCORE AMR-NB';
          break;
        case 'opus':
          outputFile = File('${tempDir.path}/output.opus');
          command = '-y -i ${inputFile.path} -c:a libopus -b:a 96k ${outputFile.path}';
          description = 'Encode with Opus';
          break;
        case 'shine':
          outputFile = File('${tempDir.path}/output.mp3');
          command = '-y -i ${inputFile.path} -c:a libshine -b:a 128k ${outputFile.path}';
          description = 'Encode with Shine (MP3)';
          break;
        case 'soxr':
          outputFile = File('${tempDir.path}/output_resampled.wav');
          command = '-y -i ${inputFile.path} -af "aresample=resampler=soxr" -ar 44100 ${outputFile.path}';
          description = 'Resample with SoXr';
          break;
        case 'speex':
          outputFile = File('${tempDir.path}/output.spx');
          command = '-y -i ${inputFile.path} -c:a libspeex -ar 16000 ${outputFile.path}';
          description = 'Encode with Speex';
          break;
        case 'twolame':
          outputFile = File('${tempDir.path}/output.mp2');
          command = '-y -i ${inputFile.path} -c:a libtwolame -b:a 192k ${outputFile.path}';
          description = 'Encode with TwoLAME (MP2)';
          break;
        case 'vo-amrwbenc':
          outputFile = File('${tempDir.path}/output.awb');
          command = '-y -i ${inputFile.path} -c:a libvo_amrwbenc -ar 16000 -b:a 23.85k ${outputFile.path}';
          description = 'Encode with AMR-WB';
          break;
        default:
          outputFile = File('${tempDir.path}/output.mp4');
          command = '-y -i ${inputFile.path} -c:v mpeg4 -preset ultrafast ${outputFile.path}';
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
          // No need to update the log string for every statistic, can be noisy
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
