import 'package:apricity/navigation/main_nav.dart';
import 'package:apricity/screens/username_screen.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
          return LoginScreen();
        } else {
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
            builder: (context, userSnapshot) {
              // Waiting for user document → show loading
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                final profileComplete = userData['profileComplete'] ?? false;

                if (profileComplete) {
                  return MainNav(cameras: cameras);
                } else {
                  return const UsernameSelectionScreen();
                }
              } else {
                return const UsernameSelectionScreen();
              }
            },
          );
        }
      },
    );
  }
}
