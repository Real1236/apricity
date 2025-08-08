import 'package:apricity/services/auth_service.dart';
import 'package:flutter/material.dart';

class UsernameSelectionScreen extends StatefulWidget {
  const UsernameSelectionScreen({super.key});

  @override
  State<UsernameSelectionScreen> createState() =>
      _UsernameSelectionScreenState();
}

class _UsernameSelectionScreenState extends State<UsernameSelectionScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isAvailable = true;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _checkUsername() async {
    final username = _usernameController.text.trim();

    if (username.isEmpty) {
      setState(() {
        _errorMessage = null;
        _isAvailable = true;
      });
      return;
    }

    if (username.length < 3) {
      setState(() {
        _errorMessage = 'Username must be at least 3 characters';
        _isAvailable = false;
      });
      return;
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      setState(() {
        _errorMessage =
            'Username can only contain letters, numbers, and underscores';
        _isAvailable = false;
      });
      return;
    }

    final isAvailable = await _authService.isUsernameAvailable(username);
    setState(() {
      _isAvailable = isAvailable;
      _errorMessage = isAvailable ? null : 'Username is already taken';
    });
  }

  Future<void> _completeProfile() async {
    final username = _usernameController.text.trim();

    if (username.isEmpty || !_isAvailable) return;

    setState(() {
      _isLoading = true;
    });

    final success = await _authService.completeProfile(username);

    if (success && mounted) {
      // Profile completed, navigate to main app
      Navigator.of(context).pushReplacementNamed('/main');
    } else if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to save username. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.person_add,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Choose Your Username',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This is how other users will find you',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixText: '@',
                  border: const OutlineInputBorder(),
                  errorText: _errorMessage,
                  suffixIcon: _usernameController.text.isNotEmpty
                      ? Icon(
                          _isAvailable ? Icons.check_circle : Icons.error,
                          color: _isAvailable ? Colors.green : Colors.red,
                        )
                      : null,
                ),
                onChanged: (_) => _checkUsername(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed:
                    _isLoading ||
                        !_isAvailable ||
                        _usernameController.text.trim().isEmpty
                    ? null
                    : _completeProfile,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
