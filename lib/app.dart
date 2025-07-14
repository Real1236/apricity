import 'package:apricity/gates/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

/// Root widget with bottom navigation (Timeline ⟷ Snap).
class ApricityApp extends StatelessWidget {
  const ApricityApp({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apricity',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orangeAccent),
        useMaterial3: true,
      ),
      home: AuthGate(cameras: cameras),
    );
  }
}
