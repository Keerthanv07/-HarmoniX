import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class AudioProvider extends ChangeNotifier {
  final _audioRecorder = Record();
  String? _recordedFilePath;
  bool _isRecording = false;

  String? get recordedFilePath => _recordedFilePath;
  bool get isRecording => _isRecording;

  Future<void> startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final filePath = path.join(directory.path, 'recorded_audio.m4a');
        
        await _audioRecorder.start(
          path: filePath,
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          samplingRate: 44100,
        );
        
        _isRecording = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _isRecording = false;
      if (path != null) {
        _recordedFilePath = path;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  Future<void> loadAudioFile(File file) async {
    _recordedFilePath = file.path;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }
}
