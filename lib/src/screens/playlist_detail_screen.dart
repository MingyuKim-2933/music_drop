import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/playlist.dart';
import '../models/song.dart';
import '../repositories/playlist_repository.dart';
import '../services/auth_service.dart';
import 'playlists_screen.dart';
import 'song_search_screen.dart';

class PlaylistDetailScreen extends StatefulWidget {
  const PlaylistDetailScreen({super.key, required this.playlist});

  final Playlist playlist;

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  late Playlist _playlist = widget.playlist;

  bool get _isMine =>
      _playlist.ownerId == context.read<AuthService>().user?.id;

  Future<void> _addSongs() async {
    final added = await Navigator.of(context).push<List<Song>>(
      MaterialPageRoute(builder: (_) => const SongSearchScreen()),
    );
    if (added == null || added.isEmpty || !mounted) return;
    final repo = context.read<PlaylistRepository>();
    Playlist updated = _playlist;
    for (final song in added) {
      updated = await repo.addSong(_playlist.id, song);
    }
    if (mounted) setState(() => _playlist = updated);
  }

  Future<void> _toggleLike() async {
    final updated =
        await context.read<PlaylistRepository>().toggleLike(_playlist);
    if (mounted) setState(() => _playlist = updated);
  }

  Future<void> _fork() async {
    final me = context.read<AuthService>().user;
    await context.read<PlaylistRepository>().fork(
          _playlist,
          myId: me?.id ?? 'unknown',
          myNickname: me?.nickname ?? '나',
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('내 플레이리스트로 퍼왔어요! ${_playlist.emoji}')),
    );
  }

  Future<void> _rename() async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => PlaylistFormDialog(
        initialTitle: _playlist.title,
        initialEmoji: _playlist.emoji,
      ),
    );
    if (result == null || !mounted) return;
    final updated = await context.read<PlaylistRepository>().updatePlaylist(
          _playlist.id,
          title: result.$1,
          emoji: result.$2,
        );
    if (mounted) setState(() => _playlist = updated);
  }

  Future<void> _onReorderSongs(int oldIndex, int newIndex) async {
    final songs = [..._playlist.songs];
    final song = songs.removeAt(oldIndex);
    songs.insert(newIndex, song);
    setState(() => _playlist = _playlist.copyWith(songs: songs));
    final updated = await context.read<PlaylistRepository>().reorderSongs(
          _playlist.id,
          songs.map((s) => s.trackId).toList(),
        );
    if (mounted) setState(() => _playlist = updated);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1526),
        title: const Text('플레이리스트 삭제'),
        content: Text('"${_playlist.title}"을(를) 삭제할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<PlaylistRepository>().deletePlaylist(_playlist.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('${_playlist.emoji} ${_playlist.title}'),
        actions: [
          if (_isMine) ...[
            IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: '이름 변경',
                onPressed: _rename),
            IconButton(
                icon: const Icon(Icons.delete_outline), onPressed: _delete),
          ],
        ],
      ),
      floatingActionButton: _isMine
          ? FloatingActionButton.extended(
              onPressed: _addSongs,
              icon: const Icon(Icons.search),
              label: const Text('곡 추가'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_playlist.ownerNickname} · ${_playlist.songs.length}곡',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.white54),
                      ),
                      if (_playlist.forkedFromTitle != null)
                        Text(
                          '↻ ${_playlist.forkedFromTitle} 에서 퍼옴',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: Colors.white38),
                        ),
                    ],
                  ),
                ),
                // 좋아요
                TextButton.icon(
                  onPressed: _toggleLike,
                  icon: Icon(
                    _playlist.likedByMe
                        ? Icons.favorite
                        : Icons.favorite_border,
                    size: 18,
                    color: _playlist.likedByMe
                        ? Colors.pinkAccent
                        : Colors.white70,
                  ),
                  label: Text('${_playlist.likeCount}'),
                ),
                // 퍼가기 (내 것이 아닐 때만)
                if (!_isMine)
                  FilledButton.tonalIcon(
                    onPressed: _fork,
                    icon: const Icon(Icons.library_add, size: 18),
                    label: const Text('퍼가기'),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: _playlist.songs.isEmpty
                ? const Center(
                    child: Text('아직 곡이 없어요.\n검색해서 추가해 보세요!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54)),
                  )
                : _isMine
                    // 내 플레이리스트: 드래그로 곡 순서 변경
                    ? ReorderableListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                        itemCount: _playlist.songs.length,
                        onReorderItem: _onReorderSongs,
                        proxyDecorator: (child, _, _) => Material(
                          color: Colors.transparent,
                          child: child,
                        ),
                        itemBuilder: (context, i) {
                          final song = _playlist.songs[i];
                          return _SongTile(
                            key: ValueKey(song.trackId),
                            song: song,
                            reorderIndex: i,
                            onRemove: () async {
                              final updated = await context
                                  .read<PlaylistRepository>()
                                  .removeSong(_playlist.id, song.trackId);
                              if (mounted) {
                                setState(() => _playlist = updated);
                              }
                            },
                          );
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                        itemCount: _playlist.songs.length,
                        itemBuilder: (context, i) =>
                            _SongTile(song: _playlist.songs[i]),
                      ),
          ),
        ],
      ),
    );
  }
}

class _SongTile extends StatelessWidget {
  const _SongTile({super.key, required this.song, this.onRemove, this.reorderIndex});

  final Song song;
  final VoidCallback? onRemove;
  final int? reorderIndex; // 있으면 드래그 핸들 표시

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1526),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: song.artworkUrl != null
              ? Image.network(song.artworkUrl!,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _ArtFallback())
              : const _ArtFallback(),
        ),
        title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(song.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 전곡은 외부 스트리밍에서 — 스토어/스트리밍 링크 열기
            if (song.storeUrl != null)
              IconButton(
                icon: const Icon(Icons.open_in_new,
                    size: 18, color: Colors.white54),
                tooltip: '스트리밍에서 듣기',
                onPressed: () => launchUrl(Uri.parse(song.storeUrl!),
                    mode: LaunchMode.externalApplication),
              ),
            if (onRemove != null)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline,
                    size: 18, color: Colors.white38),
                onPressed: onRemove,
              ),
            if (reorderIndex != null)
              ReorderableDragStartListener(
                index: reorderIndex!,
                child: const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child:
                      Icon(Icons.drag_handle, size: 20, color: Colors.white38),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ArtFallback extends StatelessWidget {
  const _ArtFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      color: Colors.white10,
      child: const Icon(Icons.music_note, size: 20, color: Colors.white38),
    );
  }
}
