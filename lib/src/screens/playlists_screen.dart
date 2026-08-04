import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/playlist.dart';
import '../repositories/playlist_repository.dart';
import '../services/auth_service.dart';
import 'playlist_detail_screen.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  List<Playlist> _mine = [];
  List<Playlist> _explore = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = context.read<PlaylistRepository>();
    final results = await Future.wait([
      repo.fetchMyPlaylists(),
      repo.fetchExplore(),
    ]);
    if (!mounted) return;
    setState(() {
      _mine = results[0];
      _explore = results[1];
      _loading = false;
    });
  }

  Future<void> _createPlaylist() async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => const _CreatePlaylistDialog(),
    );
    if (result == null || !mounted) return;
    final me = context.read<AuthService>().user;
    await context.read<PlaylistRepository>().createPlaylist(
          title: result.$1,
          emoji: result.$2,
          ownerId: me?.id ?? 'unknown',
          ownerNickname: me?.nickname ?? '나',
        );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('플레이리스트',
            style: TextStyle(fontWeight: FontWeight.w800)),
        bottom: TabBar(
          controller: _tab,
          tabs: const [Tab(text: '내 플레이리스트'), Tab(text: '둘러보기')],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createPlaylist,
        icon: const Icon(Icons.add),
        label: const Text('새 플레이리스트'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                _PlaylistList(
                  playlists: _mine,
                  emptyMessage: '첫 플레이리스트를 만들어 보세요!',
                  onChanged: _load,
                ),
                _PlaylistList(
                  playlists: _explore,
                  emptyMessage: '아직 둘러볼 플레이리스트가 없어요',
                  onChanged: _load,
                ),
              ],
            ),
    );
  }
}

class _PlaylistList extends StatelessWidget {
  const _PlaylistList({
    required this.playlists,
    required this.emptyMessage,
    required this.onChanged,
  });

  final List<Playlist> playlists;
  final String emptyMessage;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    if (playlists.isEmpty) {
      return Center(
        child: Text(emptyMessage,
            style: const TextStyle(color: Colors.white54)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      itemCount: playlists.length,
      itemBuilder: (context, i) {
        final p = playlists[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1526),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.white10,
              child: Text(p.emoji, style: const TextStyle(fontSize: 20)),
            ),
            title: Text(p.title,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
              '${p.ownerNickname} · ${p.songs.length}곡'
              '${p.forkedFromTitle != null ? ' · 퍼옴' : ''}',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  p.likedByMe ? Icons.favorite : Icons.favorite_border,
                  size: 16,
                  color: p.likedByMe ? Colors.pinkAccent : Colors.white38,
                ),
                const SizedBox(width: 4),
                Text('${p.likeCount}',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12)),
              ],
            ),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PlaylistDetailScreen(playlist: p),
                ),
              );
              onChanged();
            },
          ),
        );
      },
    );
  }
}

class _CreatePlaylistDialog extends StatefulWidget {
  const _CreatePlaylistDialog();

  @override
  State<_CreatePlaylistDialog> createState() => _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends State<_CreatePlaylistDialog> {
  final _title = TextEditingController();
  String _emoji = '🎵';
  static const _emojis = ['🎵', '🔥', '🌙', '💜', '🏃', '📚', '☔️', '🚗'];

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1526),
      title: const Text('새 플레이리스트'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '이름',
              hintText: '예) 새벽 감성 모음',
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (final e in _emojis)
                GestureDetector(
                  onTap: () => setState(() => _emoji = e),
                  child: CircleAvatar(
                    backgroundColor:
                        _emoji == e ? const Color(0xFF7C4DFF) : Colors.white10,
                    child: Text(e),
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            final title = _title.text.trim();
            if (title.isEmpty) return;
            Navigator.of(context).pop((title, _emoji));
          },
          child: const Text('만들기'),
        ),
      ],
    );
  }
}
