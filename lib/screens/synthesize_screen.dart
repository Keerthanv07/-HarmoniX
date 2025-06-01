import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:icm/providers/synthesis_provider.dart';
import 'package:just_audio/just_audio.dart';

class SynthesizeScreen extends StatefulWidget {
  const SynthesizeScreen({super.key});

  @override
  State<SynthesizeScreen> createState() => _SynthesizeScreenState();
}

class _SynthesizeScreenState extends State<SynthesizeScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _selectedRaga;
  String? _selectedTala;
  String? _selectedInstrument;
  double _duration = 60;
  double _tempo = 80;
  bool _isGenerating = false;
  String? _generatedAudioPath;

  final List<String> _ragas = [
    'Yaman',
    'Bhairav',
    'Darbari',
    'Bhupali',
    'Malkauns',
    'Bageshri',
  ];

  final List<String> _talas = [
    'Teentaal',
    'Jhaptaal',
    'Ektaal',
    'Rupak',
    'Keherwa',
  ];

  final List<String> _instruments = [
    'Sitar',
    'Sarod',
    'Bansuri',
    'Santoor',
    'Violin',
  ];

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Synthesize Music'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSynthesisParameters(),
            const SizedBox(height: 20),
            _buildGenerateSection(),
            if (_isGenerating)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Generating composition...'),
                  ],
                ),
              ),
            if (_generatedAudioPath != null) _buildPlaybackControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildSynthesisParameters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Composition Parameters',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedRaga,
              decoration: const InputDecoration(
                labelText: 'Raga',
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
                labelText: 'Tala',
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
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedInstrument,
              decoration: const InputDecoration(
                labelText: 'Primary Instrument',
                border: OutlineInputBorder(),
              ),
              items: _instruments.map((instrument) {
                return DropdownMenuItem(
                  value: instrument,
                  child: Text(instrument),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedInstrument = value;
                });
              },
            ),
            const SizedBox(height: 24),
            Text('Duration (seconds): ${_duration.round()}'),
            Slider(
              value: _duration,
              min: 30,
              max: 300,
              divisions: 27,
              label: _duration.round().toString(),
              onChanged: (value) {
                setState(() {
                  _duration = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Text('Tempo (BPM): ${_tempo.round()}'),
            Slider(
              value: _tempo,
              min: 60,
              max: 180,
              divisions: 120,
              label: _tempo.round().toString(),
              onChanged: (value) {
                setState(() {
                  _tempo = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.music_note),
              label: const Text('Generate Composition'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              onPressed: _canGenerate() ? _generateComposition : null,
            ),
            if (_selectedRaga != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  'Will generate a $_selectedRaga composition in $_selectedTala on $_selectedInstrument',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaybackControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generated Composition',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: _playGeneratedAudio,
                  tooltip: 'Play',
                ),
                IconButton(
                  icon: const Icon(Icons.stop),
                  onPressed: _stopPlayback,
                  tooltip: 'Stop',
                ),
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: _downloadComposition,
                  tooltip: 'Download',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _canGenerate() {
    return _selectedRaga != null &&
        _selectedTala != null &&
        _selectedInstrument != null &&
        !_isGenerating;
  }

  Future<void> _generateComposition() async {
    if (!_canGenerate()) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      final synthesisProvider = Provider.of<SynthesisProvider>(context, listen: false);
      final result = await synthesisProvider.generateComposition(
        raga: _selectedRaga!,
        tala: _selectedTala!,
        instrument: _selectedInstrument!,
        duration: _duration.round(),
        tempo: _tempo.round(),
      );

      setState(() {
        _generatedAudioPath = result.audioPath;
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Composition generated successfully!')),
      );
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating composition: $e')),
      );
    }
  }

  Future<void> _playGeneratedAudio() async {
    if (_generatedAudioPath == null) return;
    await _audioPlayer.setFilePath(_generatedAudioPath!);
    await _audioPlayer.play();
  }

  Future<void> _stopPlayback() async {
    await _audioPlayer.stop();
  }

  Future<void> _downloadComposition() async {
    // Implement download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download functionality coming soon!')),
    );
  }
}
