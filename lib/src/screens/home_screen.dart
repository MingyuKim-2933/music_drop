import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/friend.dart';
import '../models/friend_group.dart';
import '../models/track.dart';
import '../repositories/friends_repository.dart';
import '../services/now_playing_service.dart';
import '../widgets/error_retry.dart';
import '../widgets/friend_tile.dart';
import '../widgets/now_playing_card.dart';
import 'friend_groups_screen.dart';
import 'invite_friends_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Friend>> _friends;
  List<FriendGroup> _groups = [];
  String? _selectedGroupId; // null = 전체

  @override
  void initState() {
    super.initState();
    _friends = context.read<FriendsRepository>().fetchFriends();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final groups = await context.read<FriendsRepository>().fetchGroups();
    if (mounted) {
      setState(() {
        _groups = groups;
        // 선택 중이던 그룹이 사라졌으면 전체로
        if (_selectedGroupId != null &&
            !groups.any((g) => g.id == _selectedGroupId)) {
          _selectedGroupId = null;
        }
      });
    }
  }

  /// 나와 같은 곡을 지금 듣고 있는지 (제목+아티스트 비교)
  bool _isSameSong(NowPlaying? mine, NowPlaying? theirs) {
    if (mine == null || theirs == null) return false;
    if (!mine.isPlaying || !theirs.isPlaying) return false;
    String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    return norm(mine.title) == norm(theirs.title) &&
        norm(mine.artist) == norm(theirs.artist);
  }

  void _showReactions(BuildContext context) {
    final future = context.read<FriendsRepository>().fetchReceivedReactions();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1526),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: FutureBuilder(
            future: future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final reactions = snapshot.data!;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('받은 반응',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  if (reactions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: Text('아직 받은 반응이 없어요',
                            style: TextStyle(color: Colors.white54)),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final r in reactions)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Text(r.emoji,
                                  style: const TextStyle(fontSize: 22)),
                              title: Text(
                                r.trackTitle != null
                                    ? '${r.fromNickname}님이 "${r.trackTitle}" 듣는 걸 좋아했어요'
                                    : '${r.fromNickname}님이 반응을 보냈어요',
                                style: const TextStyle(fontSize: 14),
                              ),
                              subtitle: Text(
                                _timeAgo(r.createdAt),
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }

  Future<void> _refresh() async {
    final nowPlayingService = context.read<NowPlayingService>();
    setState(() {
      _friends = context.read<FriendsRepository>().fetchFriends();
    });
    await _loadGroups();
    await nowPlayingService.refreshConnections();
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
            icon: const Icon(Icons.favorite_border),
            tooltip: '받은 반응',
            onPressed: () => _showReactions(context),
          ),
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
            Row(
              children: [
                Text(
                  '친구들',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () async {
                    final friends = await _friends;
                    if (!context.mounted) return;
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FriendGroupsScreen(friends: friends),
                      ),
                    );
                    await _loadGroups();
                  },
                  icon: const Icon(Icons.group_work_outlined, size: 16),
                  label: const Text('그룹', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
            if (_groups.isNotEmpty) _buildGroupChips(),
            const SizedBox(height: 12),
            FutureBuilder<List<Friend>>(
              future: _friends,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ErrorRetry(
                    message: '친구 목록을 불러오지 못했어요',
                    onRetry: () => setState(() {
                      _friends =
                          context.read<FriendsRepository>().fetchFriends();
                    }),
                  );
                }
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
                // 선택된 그룹으로 필터
                final group = _groups
                    .where((g) => g.id == _selectedGroupId)
                    .firstOrNull;
                final visible = group == null
                    ? snapshot.data!
                    : snapshot.data!
                        .where((f) => group.memberIds.contains(f.id))
                        .toList();

                if (visible.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text('이 그룹에 아직 친구가 없어요',
                          style: TextStyle(color: Colors.white54)),
                    ),
                  );
                }

                // 같은 곡 듣는 친구를 맨 위로
                final sorted = [...visible]..sort((a, b) {
                    final sa = _isSameSong(nowPlaying, a.nowPlaying) ? 0 : 1;
                    final sb = _isSameSong(nowPlaying, b.nowPlaying) ? 0 : 1;
                    return sa.compareTo(sb);
                  });
                final sameCount = sorted
                    .where((f) => _isSameSong(nowPlaying, f.nowPlaying))
                    .length;

                return Column(
                  children: [
                    if (sameCount > 0)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C4DFF), Color(0xFF4527A0)],
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text('🎧', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '지금 친구 $sameCount명과 같은 곡을 듣고 있어요!',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    for (final friend in sorted)
                      FriendTile(
                        friend: friend,
                        sameSong: _isSameSong(nowPlaying, friend.nowPlaying),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 그룹 필터 칩 (전체 + 각 그룹)
  Widget _buildGroupChips() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('전체'),
              selected: _selectedGroupId == null,
              onSelected: (_) => setState(() => _selectedGroupId = null),
            ),
          ),
          for (final g in _groups)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('${g.emoji} ${g.name}'),
                selected: _selectedGroupId == g.id,
                onSelected: (_) => setState(() => _selectedGroupId = g.id),
              ),
            ),
        ],
      ),
    );
  }
}
