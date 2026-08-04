import 'dart:async';

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
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

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
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = context.read<PlaylistRepository>();
    final results = await Future.wait([
      repo.fetchMyPlaylists(),
      repo.fetchExplore(query: _searchController.text),
    ]);
    if (!mounted) return;
    setState(() {
      _mine = results[0];
      _explore = results[1];
      _loading = false;
    });
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () async {
      final explore = await context
          .read<PlaylistRepository>()
          .fetchExplore(query: _searchController.text);
      if (mounted) setState(() => _explore = explore);
    });
  }

  Future<void> _createPlaylist() async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => const PlaylistFormDialog(),
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

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      final item = _mine.removeAt(oldIndex);
      _mine.insert(newIndex, item);
    });
    await context
        .read<PlaylistRepository>()
        .reorderMyPlaylists(_mine.map((p) => p.id).toList());
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
                // ── 내 플레이리스트 (드래그로 순서 변경) ──
                _mine.isEmpty
                    ? const Center(
                        child: Text('첫 플레이리스트를 만들어 보세요!',
                            style: TextStyle(color: Colors.white54)),
                      )
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                        itemCount: _mine.length,
                        onReorderItem: _onReorder,
                        proxyDecorator: (child, _, _) => Material(
                          color: Colors.transparent,
                          child: child,
                        ),
                        itemBuilder: (context, i) => Padding(
                          key: ValueKey(_mine[i].id),
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PlaylistTile(
                            playlist: _mine[i],
                            showDragHandle: true,
                            index: i,
                            onChanged: _load,
                          ),
                        ),
                      ),
                // ── 둘러보기 (검색 + 좋아요순) ──
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: '플레이리스트 검색',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          filled: true,
                          fillColor: const Color(0xFF1A1526),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _explore.isEmpty
                          ? Center(
                              child: Text(
                                _searchController.text.isEmpty
                                    ? '아직 둘러볼 플레이리스트가 없어요'
                                    : '검색 결과가 없어요',
                                style:
                                    const TextStyle(color: Colors.white54),
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 90),
                              itemCount: _explore.length,
                              itemBuilder: (context, i) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _PlaylistTile(
                                  playlist: _explore[i],
                                  onChanged: _load,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  const _PlaylistTile({
    required this.playlist,
    required this.onChanged,
    this.showDragHandle = false,
    this.index = 0,
  });

  final Playlist playlist;
  final VoidCallback onChanged;
  final bool showDragHandle;
  final int index;

  @override
  Widget build(BuildContext context) {
    final p = playlist;
    return Container(
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
              size: 15,
              color: p.likedByMe ? Colors.pinkAccent : Colors.white38,
            ),
            const SizedBox(width: 3),
            Text('${p.likeCount}',
                style:
                    const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(width: 10),
            const Icon(Icons.library_add,
                size: 15, color: Colors.white38),
            const SizedBox(width: 3),
            Text('${p.forkCount}',
                style:
                    const TextStyle(color: Colors.white54, fontSize: 12)),
            if (showDragHandle) ...[
              const SizedBox(width: 8),
              ReorderableDragStartListener(
                index: index,
                child:
                    const Icon(Icons.drag_handle, color: Colors.white38),
              ),
            ],
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
  }
}

/// 플레이리스트 생성/수정 다이얼로그 (이름 + 이모지)
class PlaylistFormDialog extends StatefulWidget {
  const PlaylistFormDialog({super.key, this.initialTitle, this.initialEmoji});

  final String? initialTitle;
  final String? initialEmoji;

  @override
  State<PlaylistFormDialog> createState() => _PlaylistFormDialogState();
}

class _PlaylistFormDialogState extends State<PlaylistFormDialog> {
  late final _title = TextEditingController(text: widget.initialTitle);
  late String _emoji = widget.initialEmoji ?? '🎵';
  static const _emojis = ['🎵', '🔥', '🌙', '💜', '🏃', '🏋️', '📚', '☔️', '🚗'];

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialTitle != null;
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1526),
      title: Text(isEdit ? '플레이리스트 수정' : '새 플레이리스트'),
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
            runSpacing: 8,
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
          child: Text(isEdit ? '저장' : '만들기'),
        ),
      ],
    );
  }
}
