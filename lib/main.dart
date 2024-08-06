import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'recording.dart';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(RecordingAdapter());
  await Hive.openBox<Recording>('recordings');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Recorder and Player',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AudioPage(),
    );
  }
}

class AudioPage extends StatefulWidget {
  const AudioPage({super.key});

  @override
  AudioPageState createState() => AudioPageState();
}

class AudioPageState extends State<AudioPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _filePath;
  double _currentPosition = 0;
  double _totalDuration = 0;

  @override
  void dispose() {
    _audioPlayer.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final bool isPermissionGranted = await _recorder.hasPermission();
    if (!isPermissionGranted) {
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    String fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _filePath = '${directory.path}/$fileName';

    const config = RecordConfig(
      encoder: AudioEncoder.aacLc,
      sampleRate: 44100,
      bitRate: 128000,
    );

    await _recorder.start(config, path: _filePath!);
    setState(() {
      _isRecording = true;
    });

    var box = Hive.box<Recording>('recordings');
    box.add(Recording(filePath: _filePath!, timestamp: DateTime.now()));
  }

  Future<void> _stopRecording() async {
    await _recorder.stop();
    setState(() {
      _isRecording = false;
    });
  }

  Future<void> _playRecording(String filePath) async {
    await _audioPlayer.setFilePath(filePath);
    _totalDuration = _audioPlayer.duration?.inSeconds.toDouble() ?? 0;
    _audioPlayer.play();

    _audioPlayer.positionStream.listen((position) {
      setState(() {
        _currentPosition = position.inSeconds.toDouble();
      });
    });
  }

  Future<void> _deleteRecording(int index) async {
    var box = Hive.box<Recording>('recordings');
    Recording? recording = box.getAt(index);
    if (recording != null) {
      // Hapus file dari sistem file
      final file = File(recording.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      // Hapus dari Hive
      await box.deleteAt(index);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    var box = Hive.box<Recording>('recordings');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modern Audio Recorder'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(
              _isRecording ? Icons.mic : Icons.mic_none,
              size: 100,
              color: _isRecording ? Colors.red : Colors.blue,
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isRecording ? null : _startRecording,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                  ),
                  child: const Text('Record'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _isRecording ? _stopRecording : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                  ),
                  child: const Text('Stop'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: box.length,
                itemBuilder: (context, index) {
                  Recording recording = box.getAt(index) as Recording;
                  return ListTile(
                    title: Text('Recording ${index + 1}'),
                    subtitle: Text(recording.timestamp.toString()),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.play_arrow),
                          onPressed: () => _playRecording(recording.filePath),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _deleteRecording(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Slider(
              value: _currentPosition,
              max: _totalDuration,
              onChanged: (value) {
                setState(() {
                  _currentPosition = value;
                });
                _audioPlayer.seek(Duration(seconds: value.toInt()));
              },
            ),
          ],
        ),
      ),
    );
  }
}



//todo oke tapi delete blm bisa terhapus dari device
// import 'package:flutter/material.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:record/record.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:path_provider/path_provider.dart';
// import 'recording.dart';

// void main() async {
//   await Hive.initFlutter();
//   Hive.registerAdapter(RecordingAdapter());
//   await Hive.openBox<Recording>('recordings');
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Audio Recorder and Player',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: const AudioPage(),
//     );
//   }
// }

// class AudioPage extends StatefulWidget {
//   const AudioPage({super.key});

//   @override
//   AudioPageState createState() => AudioPageState();
// }

// class AudioPageState extends State<AudioPage> {
//   final AudioPlayer _audioPlayer = AudioPlayer();
//   final AudioRecorder _recorder = AudioRecorder();
//   bool _isRecording = false;
//   String? _filePath;
//   double _currentPosition = 0;
//   double _totalDuration = 0;

//   @override
//   void dispose() {
//     _audioPlayer.dispose();
//     _recorder.dispose();
//     super.dispose();
//   }

//   Future<void> _startRecording() async {
//     final bool isPermissionGranted = await _recorder.hasPermission();
//     if (!isPermissionGranted) {
//       return;
//     }

//     final directory = await getApplicationDocumentsDirectory();
//     // String fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
//     String fileName = 'recording_${DateTime.now()}.m4a';
//     _filePath = '${directory.path}/$fileName';

//     const config = RecordConfig(
//       encoder: AudioEncoder.aacLc,
//       sampleRate: 44100,
//       bitRate: 128000,
//     );

//     await _recorder.start(config, path: _filePath!);
//     setState(() {
//       _isRecording = true;
//     });

//     var box = Hive.box<Recording>('recordings');
//     box.add(Recording(filePath: _filePath!, timestamp: DateTime.now()));
//   }

//   Future<void> _stopRecording() async {
//     await _recorder.stop();
//     setState(() {
//       _isRecording = false;
//     });
//   }

//   Future<void> _playRecording(String filePath) async {
//     await _audioPlayer.setFilePath(filePath);
//     _totalDuration = _audioPlayer.duration?.inSeconds.toDouble() ?? 0;
//     _audioPlayer.play();

//     _audioPlayer.positionStream.listen((position) {
//       setState(() {
//         _currentPosition = position.inSeconds.toDouble();
//       });
//     });
//   }

//   Future<void> _deleteRecording(int index) async {
//     var box = Hive.box<Recording>('recordings');
//     await box.deleteAt(index);
//     setState(() {});
//   }

//   @override
//   Widget build(BuildContext context) {
//     var box = Hive.box<Recording>('recordings');
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Modern Audio Recorder'),
//         elevation: 0,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           children: [
//             Icon(
//               _isRecording ? Icons.mic : Icons.mic_none,
//               size: 100,
//               color: _isRecording ? Colors.red : Colors.blue,
//             ),
//             const SizedBox(height: 40),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 ElevatedButton(
//                   onPressed: _isRecording ? null : _startRecording,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue,
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 30, vertical: 15),
//                   ),
//                   child: const Text('Record'),
//                 ),
//                 const SizedBox(width: 20),
//                 ElevatedButton(
//                   onPressed: _isRecording ? _stopRecording : null,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.red,
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 30, vertical: 15),
//                   ),
//                   child: const Text('Stop'),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: box.length,
//                 itemBuilder: (context, index) {
//                   Recording recording = box.getAt(index) as Recording;
//                   return ListTile(
//                     // title: Text('Recording ${index + 1}'),
//                     title: Text('${index + 1}'),
//                     // subtitle: Text(recording.timestamp.toString()),
//                     subtitle: Text(recording.filePath),
//                     trailing: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         IconButton(
//                           icon: const Icon(Icons.play_arrow),
//                           onPressed: () => _playRecording(recording.filePath),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.delete),
//                           onPressed: () => _deleteRecording(index),
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//               ),
//             ),
//             Slider(
//               value: _currentPosition,
//               max: _totalDuration,
//               onChanged: (value) {
//                 setState(() {
//                   _currentPosition = value;
//                 });
//                 _audioPlayer.seek(Duration(seconds: value.toInt()));
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }










//todo tanpa hive
//import 'package:flutter/material.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:record/record.dart';
// import 'package:path_provider/path_provider.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Audio Recorder and Player',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: const AudioPage(),
//     );
//   }
// }

// class AudioPage extends StatefulWidget {
//   const AudioPage({super.key});

//   @override
//   AudioPageState createState() => AudioPageState();
// }

// class AudioPageState extends State<AudioPage> {
//   final AudioPlayer _audioPlayer = AudioPlayer();
//   final AudioRecorder _recorder = AudioRecorder();
//   bool _isRecording = false;
//   String? _filePath;
//   double _currentPosition = 0;
//   double _totalDuration = 0;

//   @override
//   void dispose() {
//     _audioPlayer.dispose();
//     _recorder.dispose();
//     super.dispose();
//   }

//   Future<void> _startRecording() async {
//     final bool isPermissionGranted = await _recorder.hasPermission();
//     if (!isPermissionGranted) {
//       return;
//     }

//     final directory = await getApplicationDocumentsDirectory();
//     // Generate a unique file name using the current timestamp
//     String fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
//     _filePath = '${directory.path}/$fileName';

//     // Define the configuration for the recording
//     const config = RecordConfig(
//       // Specify the format, encoder, sample rate, etc., as needed
//       encoder: AudioEncoder.aacLc, // For example, using AAC codec
//       sampleRate: 44100, // Sample rate
//       bitRate: 128000, // Bit rate
//     );

//     // Start recording to file with the specified configuration
//     await _recorder.start(config, path: _filePath!);
//     setState(() {
//       _isRecording = true;
//     });
//   }

//   Future<void> _stopRecording() async {
//     final path = await _recorder.stop();
//     setState(() {
//       _isRecording = false;
//     });
//   }

//   Future<void> _playRecording() async {
//     if (_filePath != null) {
//       await _audioPlayer.setFilePath(_filePath!);
//       _totalDuration = _audioPlayer.duration?.inSeconds.toDouble() ?? 0;
//       _audioPlayer.play();

//       _audioPlayer.positionStream.listen((position) {
//         setState(() {
//           _currentPosition = position.inSeconds.toDouble();
//         });
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Modern Audio Recorder'),
//         elevation: 0,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               _isRecording ? Icons.mic : Icons.mic_none,
//               size: 100,
//               color: _isRecording ? Colors.red : Colors.blue,
//             ),
//             const SizedBox(height: 40),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 ElevatedButton(
//                   onPressed: _isRecording ? null : _startRecording,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue,
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 30, vertical: 15),
//                   ),
//                   child: const Text('Record'),
//                 ),
//                 const SizedBox(width: 20),
//                 ElevatedButton(
//                   onPressed: _isRecording ? _stopRecording : null,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.red,
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 30, vertical: 15),
//                   ),
//                   child: const Text('Stop'),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: !_isRecording ? _playRecording : null,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green,
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
//               ),
//               child: const Text('Play'),
//             ),
//             Slider(
//               value: _currentPosition,
//               max: _totalDuration,
//               onChanged: (value) {
//                 setState(() {
//                   _currentPosition = value;
//                 });
//                 _audioPlayer.seek(Duration(seconds: value.toInt()));
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
