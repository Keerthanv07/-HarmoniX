import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:fftea/fftea.dart';
import 'package:vector_math/vector_math.dart';

enum AnalysisModel {
  cnn,
  deepSrgm
}

class AudioProcessor {
  static const int SAMPLE_RATE = 44100;
  static const int FFT_SIZE = 2048;
  static const int HOP_LENGTH = 512;
  static const int MEL_BANDS = 128;
  
  late final Interpreter _cnnInterpreter;
  late final Interpreter _deepSrgmInterpreter;
  
  Future<void> initialize() async {
    final options = InterpreterOptions()..threads = 4;
    _cnnInterpreter = await Interpreter.fromAsset(
      'assets/models/raga_classifier_cnn.tflite', 
      options: options
    );
    _deepSrgmInterpreter = await Interpreter.fromAsset(
      'assets/models/raga_classifier_deepsrgm.tflite', 
      options: options
    );
  }

  Future<Map<String, double>> analyzeAudio(String audioPath, AnalysisModel model) async {
    // Load and preprocess audio
    final audioData = await _loadAndPreprocessAudio(audioPath);
    
    switch (model) {
      case AnalysisModel.cnn:
        return await _analyzeCNN(audioData);
      case AnalysisModel.deepSrgm:
        return await _analyzeDeepSRGM(audioData);
    }
  }

  Future<Map<String, double>> _analyzeCNN(List<double> audioData) async {
    // Generate mel spectrogram
    final melSpectrogram = _computeMelSpectrogram(audioData);
    
    // Run inference
    final outputShape = [1, 10]; // Assuming 10 raga classes
    final outputBuffer = List.filled(1 * 10, 0.0).reshape(outputShape);
    
    // Reshape melSpectrogram to match input shape expected by the model
    final inputShape = [1, melSpectrogram.length, MEL_BANDS];
    final inputBuffer = melSpectrogram.expand((row) => row).toList().reshape(inputShape);
    
    _cnnInterpreter.run(inputBuffer, outputBuffer);
    
    // Process results
    final outputList = outputBuffer.reshape([10]);
    return _processResults(outputList);
  }

  Future<Map<String, double>> _analyzeDeepSRGM(List<double> audioData) async {
    // Compute pitch contour and tonic
    final pitchContour = _computePitchContour(audioData);
    final tonic = _estimateTonic(audioData);
    
    // Normalize pitch contour relative to tonic
    final normalizedPitch = _normalizePitch(pitchContour, tonic);
    
    // Extract SRGM features
    final srgmFeatures = _extractSRGMFeatures(normalizedPitch);
    
    // Run inference
    final outputShape = [1, 10]; // Assuming 10 raga classes
    final outputBuffer = List.filled(1 * 10, 0.0).reshape(outputShape);
    
    final inputShape = [1, srgmFeatures.length];
    final inputBuffer = srgmFeatures.reshape(inputShape);
    
    _deepSrgmInterpreter.run(inputBuffer, outputBuffer);
    
    // Process results
    final outputList = outputBuffer.reshape([10]);
    return _processResults(outputList);
  }

  Future<List<double>> _loadAndPreprocessAudio(String path) async {
    final file = File(path);
    final bytes = await file.readAsBytes();
    // Convert bytes to PCM samples - proper decoding would be needed here
    List<double> samples = [];
    
    // Assuming 16-bit PCM data
    for (int i = 0; i < bytes.length - 1; i += 2) {
      final sample = ByteData.view(Uint8List.fromList([bytes[i], bytes[i + 1]]).buffer).getInt16(0, Endian.little);
      samples.add(sample / 32768.0); // Normalize to [-1.0, 1.0]
    }
    
    return samples;
  }

  List<List<double>> _computeMelSpectrogram(List<double> audioData) {
    final fftProcessor = FFT(FFT_SIZE);
    final spectrogramFrames = <List<double>>[];
    
    // Apply window function
    final window = _hannWindow(FFT_SIZE);
    
    for (var i = 0; i < audioData.length - FFT_SIZE; i += HOP_LENGTH) {
      final frame = audioData.sublist(i, i + FFT_SIZE);
      
      // Apply window
      for (var j = 0; j < frame.length; j++) {
        frame[j] *= window[j];
      }
      
      // Perform FFT using the correct method from fftea package
      final fftOutput = fftProcessor.realFft(frame);
      
      // Convert Float64x2List to power spectrum (magnitude squared)
      final melBands = _convertToMelScale(fftOutput);
      
      // Log-scale the mel spectrogram
      for (var j = 0; j < melBands.length; j++) {
        melBands[j] = log(max(melBands[j], 1e-10));
      }
      
      spectrogramFrames.add(melBands);
    }
    
    return spectrogramFrames;
  }

  List<double> _hannWindow(int size) {
    final window = List<double>.filled(size, 0.0);
    for (var i = 0; i < size; i++) {
      window[i] = 0.5 * (1 - cos(2 * pi * i / (size - 1)));
    }
    return window;
  }

  List<double> _convertToMelScale(Float64x2List fftComplex) {
    // Create mel bands array
    final melBands = List<double>.filled(MEL_BANDS, 0.0);
    
    // Calculate magnitudes (power spectrum)
    // Handling Float64x2 values which contain [real, imaginary] components
    const int spectrumLength = FFT_SIZE ~/ 2 + 1;
    final magnitudes = List<double>.filled(spectrumLength, 0.0);
    
    for (var i = 0; i < spectrumLength; i++) {
      final real = fftComplex[i].x;
      final imag = fftComplex[i].y;
      magnitudes[i] = real * real + imag * imag; // |z|^2 = a^2 + b^2
    }
    
    // Mel filterbank implementation
    final melFilters = _createMelFilterbank();
    
    for (var i = 0; i < MEL_BANDS; i++) {
      double sum = 0.0;
      for (var j = 0; j < magnitudes.length; j++) {
        sum += magnitudes[j] * melFilters[i][j];
      }
      melBands[i] = sum;
    }
    
    return melBands;
  }

  List<List<double>> _createMelFilterbank() {
    final filters = List.generate(MEL_BANDS, (_) => List<double>.filled(FFT_SIZE ~/ 2 + 1, 0.0));
    
    // Convert Hz to Mel
    double hzToMel(double hz) => 2595 * log10(1 + hz / 700);
    // Convert Mel to Hz
    double melToHz(double mel) => 700 * (pow(10, mel / 2595) - 1);
    
    const fMin = 0.0;
    const fMax = SAMPLE_RATE / 2;
    final melMin = hzToMel(fMin);
    final melMax = hzToMel(fMax);
    
    // Create mel points evenly spaced in mel scale
    final melPoints = List<double>.filled(MEL_BANDS + 2, 0.0);
    for (var i = 0; i < MEL_BANDS + 2; i++) {
      melPoints[i] = melMin + (melMax - melMin) * i / (MEL_BANDS + 1);
    }
    
    // Convert mel points to Hz
    final hzPoints = melPoints.map((mel) => melToHz(mel)).toList();
    
    // Convert Hz points to FFT bins
    final bins = hzPoints.map((hz) => (FFT_SIZE + 1) * hz / SAMPLE_RATE).toList();
    
    // Create triangular filters
    for (var i = 0; i < MEL_BANDS; i++) {
      for (var j = 0; j < filters[i].length; j++) {
        final bin = j.toDouble();
        if (bin < bins[i] || bin > bins[i + 2]) {
          filters[i][j] = 0.0;
        } else if (bin >= bins[i] && bin <= bins[i + 1]) {
          filters[i][j] = (bin - bins[i]) / (bins[i + 1] - bins[i]);
        } else if (bin >= bins[i + 1] && bin <= bins[i + 2]) {
          filters[i][j] = (bins[i + 2] - bin) / (bins[i + 2] - bins[i + 1]);
        }
      }
    }
    
    return filters;
  }

  double log10(double x) => log(x) / ln10;

  List<double> _computePitchContour(List<double> audioData) {
    // Implement pitch tracking using YIN or pYIN algorithm
    // This is a placeholder implementation
    return List.filled(1000, 440.0); // Return dummy pitch values
  }

  double _estimateTonic(List<double> audioData) {
    // Implement tonic identification
    // This is a placeholder implementation
    return 220.0; // Return dummy tonic frequency
  }

  List<double> _normalizePitch(List<double> pitchContour, double tonic) {
    return pitchContour.map((pitch) => 1200 * log2(pitch / tonic)).toList();
  }

  List<double> _extractSRGMFeatures(List<double> normalizedPitch) {
    // Implement SRGM feature extraction
    // This is a placeholder implementation
    return List.filled(128, 0.0); // Return dummy features
  }

  double log2(double x) => log(x) / ln2;

  Map<String, double> _processResults(List<double> predictions) {
    final ragas = ['Yaman', 'Bhairavi', 'Bhupali', 'Malkauns', 'Darbari',
                   'Todi', 'Khamaj', 'Bageshri', 'Durga', 'Kedar'];
    
    final results = <String, double>{};
    for (var i = 0; i < predictions.length; i++) {
      results[ragas[i]] = predictions[i];
    }
    
    return results;
  }
}

extension ListReshape<T> on List<T> {
  List<T> reshape(List<int> shape) {
    // For TensorFlow Lite, this simple pass-through is sufficient
    // as TFLite handles the reshaping internally
    return this;
  }
}
