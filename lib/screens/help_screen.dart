import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          ExpansionTile(
            title: Text('Analyzing Audio'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'To analyze an audio recording:\n\n'
                  '1. Navigate to the Analyze Audio screen\n'
                  '2. Tap the "Pick Audio File" button\n'
                  '3. Select an Indian Classical Music recording\n'
                  '4. Tap "Analyze" to process the audio\n'
                  '5. View the analysis results including raga, tala, and suggestions',
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: Text('Synthesizing Music'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'To generate Indian Classical Music:\n\n'
                  '1. Navigate to the Synthesize Music screen\n'
                  '2. Select a raga from the dropdown menu\n'
                  '3. Choose a tala and performance style\n'
                  '4. Adjust tempo, duration, and improvisation level\n'
                  '5. Tap "Generate" to create the composition\n'
                  '6. Use the playback controls to listen to the result',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}