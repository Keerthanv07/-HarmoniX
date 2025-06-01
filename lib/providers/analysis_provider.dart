import 'package:flutter/foundation.dart';
import 'package:icm/screens/analyze_screen.dart';

class AnalysisProvider extends ChangeNotifier {
  bool _isInitialized = false;
  bool _isAnalyzing = false;
  Map<String, double>? _analysisResults;
  AnalysisModel _selectedModel = AnalysisModel.cnn;

  bool get isAnalyzing => _isAnalyzing;
  Map<String, double>? get analysisResults => _analysisResults;
  AnalysisModel get selectedModel => _selectedModel;

  Future<void> initialize() async {
    if (!_isInitialized) {
      // Initialize ML models or other resources here
      _isInitialized = true;
    }
  }

  void setAnalysisModel(AnalysisModel model) {
    _selectedModel = model;
    notifyListeners();
  }

  Future<void> analyzeAudio(String audioPath) async {
    try {
      _isAnalyzing = true;
      notifyListeners();

      // Simulate analysis delay
      await Future.delayed(const Duration(seconds: 2));

      // TODO: Implement actual audio analysis
      _analysisResults = {
        'raga_probability': 0.85,
        'tala_probability': 0.78,
      };

      _isAnalyzing = false;
      notifyListeners();
    } catch (e) {
      _isAnalyzing = false;
      _analysisResults = null;
      notifyListeners();
      rethrow;
    }
  }
}

