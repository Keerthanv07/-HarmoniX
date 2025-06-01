# -HarmoniX
ICM Analyzer - Indian Classical Music Analysis Tool
# ICM Analyzer - Indian Classical Music Analysis Tool

A Flutter-based application for analyzing and synthesizing Indian Classical Music (ICM). This tool helps musicians, students, and enthusiasts understand and work with various aspects of Indian Classical Music.

## Features

- **Audio Analysis**
  - Raga Recognition
  - Tala Pattern Detection
  - Real-time Pitch Tracking
  - Musical Note (Swara) Identification

- **Audio Recording**
  - High-quality audio recording capability
  - Support for importing existing audio files
  - Multiple format support (WAV, MP3)

- **Visualization**
  - Pitch contour visualization
  - Tala cycle representation
  - Spectrogram analysis
  - Real-time waveform display

## Technical Stack

- **Frontend**: Flutter/Dart
- **Audio Processing**: TensorFlow Lite
- **ML Models**: Custom trained models for raga recognition
- **Audio Libraries**: 
  - just_audio for playback
  - record for audio recording
  - fftea for frequency analysis

## Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Android Studio / VS Code with Flutter extensions
- Python 3.8+ (for ML model training)

### Installation

1. Clone the repository
```bash
git clone https://github.com/YOUR_USERNAME/icm.git
```

2. Install dependencies
```bash
flutter pub get
```

3. Run the application
```bash
flutter run
```

### ML Model Training

For training custom models, install Python dependencies:
```bash
cd ml
pip install -r requirements.txt
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Thanks to the Flutter team for the excellent framework
- Indian Classical Music community for domain expertise
- Contributors and testers

## Contact

For any queries or suggestions, please open an issue in the repository.
