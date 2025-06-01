import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:icm/providers/audio_provider.dart';
import 'package:icm/providers/analysis_provider.dart';
import 'package:icm/screens/analyze_screen.dart';
import 'package:icm/providers/synthesis_provider.dart';
import 'package:icm/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(create: (_) => AnalysisProvider()),
        ChangeNotifierProvider(create: (_) => SynthesisProvider()),
      ],
      child: MaterialApp(
        title: 'ICM Analyzer',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
