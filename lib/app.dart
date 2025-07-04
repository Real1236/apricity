import 'package:apricity/gates/auth_gate.dart';
import 'package:apricity/screens/calendar_screen.dart';
import 'package:apricity/widgets/sign_out_dialog.dart';
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
      home: AuthGate(cameras: cameras),
    );
  }
}

class MainNav extends StatefulWidget {
  const MainNav({super.key, required this.cameras});
  final List<CameraDescription> cameras;

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _current = 0;
  final GlobalKey<GratitudeSnapScreenState> _snapKey =
      GlobalKey<GratitudeSnapScreenState>();
  final GlobalKey<CalendarScreenState> _calendarKey =
      GlobalKey<CalendarScreenState>();

  @override
  Widget build(BuildContext context) {
    final screens = [
      TimelineScreen(),
      GratitudeSnapScreen(key: _snapKey, primaryCamera: widget.cameras.first),
      CalendarScreen(key: _calendarKey),
    ];

    return Scaffold(
      appBar: _buildAppBar(),
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
            // Entering snap screen and starting camera.
            _snapKey.currentState?.startCamera();
          } else if (i != 1 && _current == 1) {
            if (_snapKey.currentState?.mounted ?? false) {
              // Leaving snap screen and stopping camera.
              _snapKey.currentState?.stopCamera();
            }
          } else if (i == 2) {
            // Refreshing calendar when entering.
            _calendarKey.currentState?.refreshCurrentMonth();
          }
          setState(() => _current = i);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    const titles = ['My Gratitude Journal', 'Gratitude Snap', 'Calendar'];
    return AppBar(
      title: Text(titles[_current]),
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'signout') showSignOutDialog(context);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'signout', child: Text('Sign out')),
          ],
        ),
      ],
    );
  }
}
