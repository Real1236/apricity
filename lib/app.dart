import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import 'screens/gratitude_snap_screen.dart';

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
      home: GratitudeSnapScreen(primaryCamera: cameras.first),
    );
  }
}
