import 'package:apricity/screens/calendar_screen.dart';
import 'package:apricity/screens/gratitude_snap_screen.dart';
import 'package:apricity/screens/timeline_screen.dart';
import 'package:apricity/widgets/sign_out_dialog.dart';
import 'package:apricity/widgets/streak_badge.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum AppTab { timeline, snap, calendar }

class MainNav extends StatefulWidget {
  const MainNav({super.key, required this.cameras});
  final List<CameraDescription> cameras;

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  late final GlobalKey<GratitudeSnapScreenState> _snapKey;
  late final GlobalKey<CalendarScreenState> _calendarKey;

  late final List<TabScreen> _tabs;
  AppTab _current = AppTab.timeline;

  @override
  void initState() {
    super.initState();
    _snapKey = GlobalKey<GratitudeSnapScreenState>();
    _calendarKey = GlobalKey<CalendarScreenState>();

    _tabs = [
      TabScreen(
        title: 'My Gratitude Journal',
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home),
        build: () => const TimelineScreen(),
      ),
      TabScreen(
        title: 'Gratitude Snap',
        icon: const Icon(Icons.photo_camera_outlined),
        selectedIcon: const Icon(Icons.photo_camera),
        build: () => GratitudeSnapScreen(
          key: _snapKey,
          primaryCamera: widget.cameras.first,
        ),
        onEnter: () => _snapKey.currentState?.startCamera(),
        onLeave: () => _snapKey.currentState?.stopCamera(),
      ),
      TabScreen(
        title: 'Calendar',
        icon: const Icon(Icons.calendar_today_outlined),
        selectedIcon: const Icon(Icons.calendar_today),
        build: () => CalendarScreen(key: _calendarKey),
        onEnter: () => _calendarKey.currentState?.refreshCurrentMonth(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _current.index,
        children: _tabs.map((t) => t.build()).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _current.index,
        destinations: _tabs
            .map(
              (t) => NavigationDestination(
                icon: t.icon,
                selectedIcon: t.selectedIcon,
                label: t.title.split(' ').first,
              ),
            )
            .toList(),
        onDestinationSelected: _onTabSelected,
      ),
    );
  }

  void _onTabSelected(int newIndex) {
    final next = AppTab.values[newIndex];
    if (next == _current) return;

    _tabs[_current.index].onLeave?.call();
    _tabs[newIndex].onEnter?.call();

    setState(() => _current = next);
  }

  /// Same streak-aware AppBar as before, but reads data from _tabs[_current].
  PreferredSizeWidget _buildAppBar() {
    final currentTab = _tabs[_current.index];

    Widget? streakWidget;
    if (_current == AppTab.timeline) {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      streakWidget = StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.doc('users/$uid').snapshots(),
        builder: (_, userSnap) {
          final int streak =
              (userSnap.data?.data()?['currentStreak'] ?? 0) as int;
          return Padding(
            padding: EdgeInsets.only(right: 12),
            child: StreakBadge(streak: streak),
          );
        },
      );
    }

    return AppBar(
      title: Text(currentTab.title),
      actions: [
        if (streakWidget != null) streakWidget,
        PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'signout') showSignOutDialog(context);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'signout', child: Text('Sign out')),
          ],
        ),
      ],
    );
  }
}

class TabScreen {
  const TabScreen({
    required this.title,
    required this.icon,
    required this.selectedIcon,
    required this.build,
    this.onEnter,
    this.onLeave,
  });

  final String title;
  final Icon icon;
  final Icon selectedIcon;
  final Widget Function() build;

  /// Optional hooks for things like starting/stopping the camera.
  final VoidCallback? onEnter;
  final VoidCallback? onLeave;
}
