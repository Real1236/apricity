import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../app.dart';

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
          return LoginScreen(
            onSignedIn: () {
              // Replace the entire stack with MainNav once login succeeds
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => MainNav(cameras: cameras)),
              );
            },
          );
        } else {
          // ───────────── SIGNED IN ─────────────
          return MainNav(cameras: cameras);
        }
      },
    );
  }
}
