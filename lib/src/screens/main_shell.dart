import 'package:flutter/material.dart';

import '../services/reaction_notification_service.dart';
import 'home_screen.dart';
import 'playlists_screen.dart';

/// 하단 탭 셸 (홈 / 플레이리스트)
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final _reactionNotifications = ReactionNotificationService();

  @override
  void initState() {
    super.initState();
    _reactionNotifications.start();
  }

  @override
  void dispose() {
    _reactionNotifications.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [HomeScreen(), PlaylistsScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: const Color(0xFF141021),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.headphones_outlined),
            selectedIcon: Icon(Icons.headphones),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.queue_music_outlined),
            selectedIcon: Icon(Icons.queue_music),
            label: '플레이리스트',
          ),
        ],
      ),
    );
  }
}
