import 'package:flutter/material.dart';

class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Text('🔥', style: TextStyle(fontSize: 16)),
      label: Text('$streak'),
    );
  }
}
