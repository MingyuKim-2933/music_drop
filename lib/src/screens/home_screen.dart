import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/friend.dart';
import '../repositories/friends_repository.dart';
import '../services/now_playing_service.dart';
import '../widgets/friend_tile.dart';
import '../widgets/now_playing_card.dart';
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
        title: const Text('듣는중 🎧',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
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
