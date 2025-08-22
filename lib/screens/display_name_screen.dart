import 'package:apricity/services/auth_service.dart';
import 'package:flutter/material.dart';

class DisplayNameSelectionScreen extends StatefulWidget {
  const DisplayNameSelectionScreen({super.key});

  @override
  State<DisplayNameSelectionScreen> createState() =>
      _DisplayNameSelectionScreenState();
}

class _DisplayNameSelectionScreenState
    extends State<DisplayNameSelectionScreen> {
  final TextEditingController _displayNameController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isAvailable = true;
  String? _errorMessage;

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _checkDisplayName() async {
    final displayName = _displayNameController.text.trim();

    if (displayName.isEmpty) {
      setState(() {
        _errorMessage = null;
        _isAvailable = true;
      });
      return;
    }

    if (displayName.length < 3) {
      setState(() {
        _errorMessage = 'Display name must be at least 3 characters';
        _isAvailable = false;
      });
      return;
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(displayName)) {
      setState(() {
        _errorMessage =
            'Display name can only contain letters, numbers, and underscores';
        _isAvailable = false;
      });
      return;
    }

    final isAvailable = await _authService.isDisplayNameAvailable(displayName);
    setState(() {
      _isAvailable = isAvailable;
      _errorMessage = isAvailable ? null : 'Display name is already taken';
    });
  }

  Future<void> _completeProfile() async {
    final displayName = _displayNameController.text.trim();

    if (displayName.isEmpty || !_isAvailable) return;

    setState(() {
      _isLoading = true;
    });

    final success = await _authService.completeProfile(displayName);

    if (success && mounted) {
      // Profile completed, navigate to main app
      Navigator.of(context).pushReplacementNamed('/main');
    } else if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to save display name. Please try again.';
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
                'Choose Your Display Name',
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
                controller: _displayNameController,
                decoration: InputDecoration(
                  labelText: 'Display Name',
                  prefixText: '@',
                  border: const OutlineInputBorder(),
                  errorText: _errorMessage,
                  suffixIcon: _displayNameController.text.isNotEmpty
                      ? Icon(
                          _isAvailable ? Icons.check_circle : Icons.error,
                          color: _isAvailable ? Colors.green : Colors.red,
                        )
                      : null,
                ),
                onChanged: (_) => _checkDisplayName(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed:
                    _isLoading ||
                        !_isAvailable ||
                        _displayNameController.text.trim().isEmpty
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
