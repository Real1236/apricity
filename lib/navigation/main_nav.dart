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

class TabScreen {
  const TabScreen({
    required this.title,
    required this.icon,
    required this.selectedIcon,
    required this.build,
    this.onEnter,
    this.onLeave,
    this.showStreak = false,
  });

  final String title;
  final Icon icon;
  final Icon selectedIcon;
  final Widget Function() build;
  final VoidCallback? onEnter;
  final VoidCallback? onLeave;
  final bool showStreak;
}

class MainNav extends StatefulWidget {
  const MainNav({super.key, required this.cameras});
  final List<CameraDescription> cameras;

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  late final GlobalKey<GratitudeSnapScreenState> _snapKey;
  late final GlobalKey<CalendarScreenState> _calendarKey;

  late final Map<AppTab, TabScreen> _tabMap;
  late final List<AppTab> _tabsInOrder;
  AppTab _current = AppTab.timeline;

  @override
  void initState() {
    super.initState();
    _snapKey = GlobalKey<GratitudeSnapScreenState>();
    _calendarKey = GlobalKey<CalendarScreenState>();

    _tabMap = {
      AppTab.timeline: TabScreen(
        title: 'My Gratitude Journal',
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home),
        build: () => const TimelineScreen(),
        showStreak: true,
      ),
      AppTab.snap: TabScreen(
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
      AppTab.calendar: TabScreen(
        title: 'Calendar',
        icon: const Icon(Icons.calendar_today_outlined),
        selectedIcon: const Icon(Icons.calendar_today),
        build: () => CalendarScreen(key: _calendarKey),
        onEnter: () => _calendarKey.currentState?.refreshCurrentMonth(),
      ),
    };

    _tabsInOrder = [AppTab.timeline, AppTab.snap, AppTab.calendar];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _tabsInOrder.indexOf(_current),
        children: _tabsInOrder.map((t) => _tabMap[t]!.build()).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabsInOrder.indexOf(_current),
        destinations: _tabsInOrder
            .map(
              (t) => NavigationDestination(
                icon: _tabMap[t]!.icon,
                selectedIcon: _tabMap[t]!.selectedIcon,
                label: _tabMap[t]!.title.split(' ').first,
              ),
            )
            .toList(),
        onDestinationSelected: _onTabTap,
      ),
    );
  }

  /* ---------------- handle taps without coupling ---------------- */
  void _onTabTap(int index) {
    final next = _tabsInOrder[index];
    if (next == _current) return;

    _tabMap[_current]!.onLeave?.call();
    _tabMap[next]!.onEnter?.call();

    setState(() => _current = next);
  }

  /* ---------------- custom AppBar ---------------- */
  PreferredSizeWidget _buildAppBar() {
    final cfg = _tabMap[_current]!;
    Widget? streak;
    if (cfg.showStreak) {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      streak = StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.doc('users/$uid').snapshots(),
        builder: (_, s) {
          final streakNum = (s.data?.data()?['currentStreak'] ?? 0) as int;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: StreakBadge(streak: streakNum),
          );
        },
      );
    }

    return AppBar(
      title: Text(cfg.title),
      actions: [
        if (streak != null) streak,
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
