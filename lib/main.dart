import 'package:flutter/material.dart';

import 'screens/workouts_screen.dart';

void main() {
  runApp(const TrainingApp());
}

class TrainingApp extends StatelessWidget {
  const TrainingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Training',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0E9F6E)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0E9F6E),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const WorkoutsScreen(),
    );
  }
}
