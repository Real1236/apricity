// widgets/sign_out_dialog.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

Future<void> showSignOutDialog(BuildContext context) async {
  final shouldSignOut = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Sign out?'),
      content: const Text(
        'You will need to sign in again to access your snaps.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Sign out'),
        ),
      ],
    ),
  );

  if (shouldSignOut == true) {
    await AuthService().signOut();
    // No manual navigation needed:
    // AuthGate listens to authStateChanges() and will rebuild to LoginScreen.
  }
}
