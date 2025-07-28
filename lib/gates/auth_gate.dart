import 'package:apricity/navigation/main_nav.dart';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.cameras});
  final List<CameraDescription> cameras;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // emits null vs user
      builder: (context, snapshot) {
        // Waiting for the first event → show splash
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          // ───────────── NOT SIGNED IN ─────────────
          return LoginScreen(onSignedIn: () {});
        } else {
          // ───────────── SIGNED IN ─────────────
          return MainNav(cameras: cameras);
        }
      },
    );
  }
}
