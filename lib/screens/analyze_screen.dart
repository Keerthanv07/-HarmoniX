import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:icm/providers/audio_provider.dart';
import 'package:icm/providers/analysis_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';

enum AnalysisModel { cnn, deepSrgm }

class AnalyzeScreen extends StatefulWidget {
  const AnalyzeScreen({super.key});

  @override
  State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen> {
  String? _selectedRaga;
  String? _selectedTala;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResults;

  final List<String> _ragas = ['Yaman', 'Bhairavi', 'Bhupali', 'Malkauns'];
  final List<String> _talas = ['Teentaal', 'Jhaptaal', 'Ektaal', 'Keherwa'];

  @override
  void initState() {
    super.initState();
    // Initialize the analysis provider
    Future.microtask(() async {
      final analysisProvider = Provider.of<AnalysisProvider>(context, listen: false);
      await analysisProvider.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyze Audio'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAnalysisParameters(),
            const SizedBox(height: 20),
            _buildAudioInputSection(),
            const SizedBox(height: 20),
            if (_isAnalyzing) const LinearProgressIndicator(),
            if (_analysisResults != null) _buildAnalysisResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisParameters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analysis Parameters',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Consumer<AnalysisProvider>(
              builder: (context, analysisProvider, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Analysis Model'),
                    const SizedBox(height: 8),
                    SegmentedButton<AnalysisModel>(
                      segments: const [
                        ButtonSegment(
                          value: AnalysisModel.cnn,
                          label: Text('CNN Model'),
                          icon: Icon(Icons.auto_awesome),
                        ),
                        ButtonSegment(
                          value: AnalysisModel.deepSrgm,
                          label: Text('DeepSRGM'),
                          icon: Icon(Icons.music_note),
                        ),
                      ],
                      selected: {analysisProvider.selectedModel},
                      onSelectionChanged: (Set<AnalysisModel> selection) {
                        analysisProvider.setAnalysisModel(selection.first);
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      analysisProvider.selectedModel == AnalysisModel.cnn
                          ? 'CNN model uses mel-spectrograms for audio analysis'
                          : 'DeepSRGM uses pitch contours and tonic-normalized features',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRaga,
              decoration: const InputDecoration(
                labelText: 'Target Raga',
                border: OutlineInputBorder(),
              ),
              items: _ragas.map((raga) {
                return DropdownMenuItem(
                  value: raga,
                  child: Text(raga),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRaga = value;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedTala,
              decoration: const InputDecoration(
                labelText: 'Target Tala',
                border: OutlineInputBorder(),
              ),
              items: _talas.map((tala) {
                return DropdownMenuItem(
                  value: tala,
                  child: Text(tala),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTala = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioInputSection() {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Audio Input',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(audioProvider.isRecording
                          ? Icons.stop
                          : Icons.mic),
                      label: Text(audioProvider.isRecording
                          ? 'Stop Recording'
                          : 'Start Recording'),
                      onPressed: () async {
                        if (audioProvider.isRecording) {
                          await audioProvider.stopRecording();
                        } else {
                          await audioProvider.startRecording();
                        }
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Audio'),
                      onPressed: _pickAudioFile,
                    ),
                  ],
                ),
                if (audioProvider.recordedFilePath != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      'Audio file: ${audioProvider.recordedFilePath!.split('/').last}',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: audioProvider.recordedFilePath != null
                        ? () => _analyzeAudio(audioProvider.recordedFilePath!)
                        : null,
                    child: const Text('Analyze Audio'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalysisResults() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analysis Results',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildWaveformChart(),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Detected Raga'),
              subtitle: Text(_analysisResults?['raga'] ?? 'Unknown'),
              leading: const Icon(Icons.music_note),
            ),
            ListTile(
              title: const Text('Detected Tala'),
              subtitle: Text(_analysisResults?['tala'] ?? 'Unknown'),
              leading: const Icon(Icons.timer),
            ),
            ListTile(
              title: const Text('Accuracy Score'),
              subtitle: Text('${_analysisResults?['accuracy']}%'),
              leading: const Icon(Icons.score),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveformChart() {
    final List<FlSpot> spots = List.generate(
      50,
      (i) => FlSpot(i.toDouble(), (i % 5 - 2).toDouble()),
    );

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Theme.of(context).primaryColor,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);
      await audioProvider.loadAudioFile(file);
    }
  }

  Future<void> _analyzeAudio(String audioPath) async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      final analysisProvider = Provider.of<AnalysisProvider>(context, listen: false);
      await analysisProvider.analyzeAudio(audioPath);

      setState(() {
        _analysisResults = {
          'raga': _selectedRaga ?? 'Yaman',
          'tala': _selectedTala ?? 'Teentaal',
          'accuracy': 85,
          'suggestions': ['Adjust Ga shruti', 'Maintain steady tempo'],
        };
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error analyzing audio: $e')),
      );
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }
}

