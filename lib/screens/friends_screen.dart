import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(body: Center(child: Text('List of Friends')));
  }
}
