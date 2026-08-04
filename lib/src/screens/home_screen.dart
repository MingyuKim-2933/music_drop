import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/friend.dart';
import '../repositories/friends_repository.dart';
import '../services/now_playing_service.dart';
import '../widgets/friend_tile.dart';
import '../widgets/now_playing_card.dart';
import 'invite_friends_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Friend>> _friends;

  @override
  void initState() {
    super.initState();
    _friends = context.read<FriendsRepository>().fetchFriends();
  }

  Future<void> _refresh() async {
    setState(() {
      _friends = context.read<FriendsRepository>().fetchFriends();
    });
    await context.read<NowPlayingService>().refreshConnections();
  }

  @override
  Widget build(BuildContext context) {
    final nowPlaying = context.watch<NowPlayingService>().mine;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('MUSE 🎧',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            tooltip: '친구 찾기',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const InviteFriendsScreen()),
              );
              // 친구 추가 후 돌아오면 피드 갱신
              if (mounted) {
                setState(() {
                  _friends = context.read<FriendsRepository>().fetchFriends();
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            NowPlayingCard(nowPlaying: nowPlaying),
            const SizedBox(height: 24),
            Text(
              '친구들',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Friend>>(
              future: _friends,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.data!.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          const Text('🫂', style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 8),
                          const Text('아직 친구가 없어요',
                              style: TextStyle(color: Colors.white54)),
                          const SizedBox(height: 12),
                          FilledButton.tonalIcon(
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const InviteFriendsScreen()),
                              );
                              if (mounted) {
                                setState(() {
                                  _friends = context
                                      .read<FriendsRepository>()
                                      .fetchFriends();
                                });
                              }
                            },
                            icon: const Icon(Icons.person_add_alt_1),
                            label: const Text('친구 찾기'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final friend in snapshot.data!)
                      FriendTile(friend: friend),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
