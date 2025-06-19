import 'package:apricity/screens/calendar_screen.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import 'screens/timeline_screen.dart';
import 'screens/gratitude_snap_screen.dart';

/// Root widget with bottom navigation (Timeline ⟷ Snap).
class ApricityApp extends StatelessWidget {
  const ApricityApp({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apricity',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orangeAccent),
        useMaterial3: true,
      ),
      home: _MainNav(cameras: cameras),
    );
  }
}

class _MainNav extends StatefulWidget {
  const _MainNav({required this.cameras});
  final List<CameraDescription> cameras;

  @override
  State<_MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<_MainNav> {
  int _current = 0;
  final GlobalKey<GratitudeSnapScreenState> _snapKey =
      GlobalKey<GratitudeSnapScreenState>();

  @override
  Widget build(BuildContext context) {
    final screens = [
      TimelineScreen(),
      GratitudeSnapScreen(key: _snapKey, primaryCamera: widget.cameras.first),
      CalendarScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _current, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _current,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_camera_outlined),
            selectedIcon: Icon(Icons.photo_camera),
            label: 'Snap',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
        ],
        onDestinationSelected: (i) {
          if (i == 1 && _current != 1) {
            _snapKey.currentState?.startCamera();
          } else if (i != 1 && _current == 1) {
            _snapKey.currentState?.stopCamera();
          }
          setState(() => _current = i);
        },
      ),
    );
  }
}
