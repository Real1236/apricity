import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import 'screens/timeline_screen.dart';
import 'screens/gratitude_snap_screen.dart';

/// Root widget with bottom navigation (Timeline ⟷ Snap).
class ApricityApp extends StatelessWidget {
  const ApricityApp({Key? key, required this.cameras}) : super(key: key);

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
  const _MainNav({super.key, required this.cameras});
  final List<CameraDescription> cameras;

  @override
  State<_MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<_MainNav> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      TimelineScreen(),
      GratitudeSnapScreen(primaryCamera: widget.cameras.first),
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
        ],
        onDestinationSelected: (i) => setState(() => _current = i),
      ),
    );
  }
}
