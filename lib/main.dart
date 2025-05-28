import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'app.dart';

/// Entry point of the Apricity MVP.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Retrieve available cameras once at startup.
  final cameras = await availableCameras();
  runApp(ApricityApp(cameras: cameras));
}
