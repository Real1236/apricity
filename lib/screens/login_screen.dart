import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// A minimal login screen with a Google sign‑in button.
///
/// If [AuthService.currentUser] is already non‑null, navigates directly to
/// [onSignedIn] without showing UI.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onSignedIn});

  /// Called after a successful sign‑in.
  final VoidCallback onSignedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Auto‑skip if already signed in (e.g. returning user).
    if (_auth.currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onSignedIn());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
                icon: const Icon(Icons.g_mobiledata, size: 32),
                label: const Text('Sign in with Google'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(220, 48),
                ),
                onPressed: _handleSignIn,
              ),
      ),
    );
  }

  Future<void> _handleSignIn() async {
    setState(() => _loading = true);
    final user = await _auth.signInWithGoogle();
    if (user != null) {
      widget.onSignedIn();
    } else {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Sign‑in cancelled')));
      }
    }
  }
}
