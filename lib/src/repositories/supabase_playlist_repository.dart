import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/playlist.dart';
import '../models/song.dart';
import 'playlist_repository.dart';

/// Supabase 실데이터 플레이리스트 리포지토리.
/// RLS 정책으로 보호되므로 로그인(Supabase 세션) 상태에서만 사용한다.
class SupabasePlaylistRepository implements PlaylistRepository {
  SupabaseClient get _db => Supabase.instance.client;
  String get _uid => _db.auth.currentUser!.id;

  static const _select =
      '*, playlist_songs(*), playlist_likes(count), '
      'forks:playlists!playlists_forked_from_fkey(count), '
      'profiles!playlists_owner_id_fkey(nickname)';

  @override
  Future<List<Playlist>> fetchMyPlaylists() async {
    final rows = await _db
        .from('playlists')
        .select(_select)
        .eq('owner_id', _uid)
        .order('sort_order', ascending: true)
        .order('updated_at', ascending: false)
        .order('position',
            referencedTable: 'playlist_songs', ascending: true);
    final likedIds = await _myLikedIds();
    return rows.map((r) => _fromRow(r, likedIds)).toList();
  }

  @override
  Future<List<Playlist>> fetchExplore({String? query}) async {
    var builder = _db
        .from('playlists')
        .select(_select)
        .neq('owner_id', _uid)
        .eq('is_public', true);
    final q = query?.trim();
    if (q != null && q.isNotEmpty) {
      builder = builder.ilike('title', '%$q%');
    }
    final rows = await builder
        .order('updated_at', ascending: false)
        .order('position',
            referencedTable: 'playlist_songs', ascending: true)
        .limit(50);
    final likedIds = await _myLikedIds();
    final result = rows.map((r) => _fromRow(r, likedIds)).toList();
    // 좋아요 많은 순 (집계 컬럼은 서버 정렬 불가 → 클라이언트 정렬)
    result.sort((a, b) => b.likeCount.compareTo(a.likeCount));
    return result;
  }

  @override
  Future<Playlist> updatePlaylist(String id,
      {String? title, String? emoji}) async {
    await _db.from('playlists').update({
      'title': ?title,
      'emoji': ?emoji,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
    return _fetchOne(id);
  }

  @override
  Future<void> reorderMyPlaylists(List<String> orderedIds) async {
    for (var i = 0; i < orderedIds.length; i++) {
      await _db
          .from('playlists')
          .update({'sort_order': i}).eq('id', orderedIds[i]);
    }
  }

  @override
  Future<Playlist> reorderSongs(
      String playlistId, List<int> orderedTrackIds) async {
    for (var i = 0; i < orderedTrackIds.length; i++) {
      await _db
          .from('playlist_songs')
          .update({'position': i})
          .eq('playlist_id', playlistId)
          .eq('track_id', orderedTrackIds[i]);
    }
    return _fetchOne(playlistId);
  }

  @override
  Future<Playlist> createPlaylist({
    required String title,
    required String emoji,
    required String ownerId,
    required String ownerNickname,
  }) async {
    final row = await _db
        .from('playlists')
        .insert({'owner_id': _uid, 'title': title, 'emoji': emoji})
        .select(_select)
        .single();
    return _fromRow(row, const {});
  }

  @override
  Future<void> deletePlaylist(String id) async {
    await _db.from('playlists').delete().eq('id', id);
  }

  @override
  Future<Playlist> addSong(String playlistId, Song song) async {
    await _db.from('playlist_songs').upsert({
      'playlist_id': playlistId,
      'track_id': song.trackId,
      'title': song.title,
      'artist': song.artist,
      'artwork_url': song.artworkUrl,
      'preview_url': song.previewUrl,
      'store_url': song.storeUrl,
    });
    await _touch(playlistId);
    return _fetchOne(playlistId);
  }

  @override
  Future<Playlist> removeSong(String playlistId, int trackId) async {
    await _db
        .from('playlist_songs')
        .delete()
        .eq('playlist_id', playlistId)
        .eq('track_id', trackId);
    await _touch(playlistId);
    return _fetchOne(playlistId);
  }

  @override
  Future<Playlist> toggleLike(Playlist playlist) async {
    if (playlist.likedByMe) {
      await _db
          .from('playlist_likes')
          .delete()
          .eq('playlist_id', playlist.id)
          .eq('user_id', _uid);
    } else {
      await _db.from('playlist_likes').upsert({
        'playlist_id': playlist.id,
        'user_id': _uid,
      });
    }
    return _fetchOne(playlist.id);
  }

  @override
  Future<Playlist> fork(Playlist source,
      {required String myId, required String myNickname}) async {
    final row = await _db
        .from('playlists')
        .insert({
          'owner_id': _uid,
          'title': source.title,
          'emoji': source.emoji,
          'forked_from': source.id,
          'forked_from_title':
              '${source.ownerNickname}님의 ${source.title}',
        })
        .select()
        .single();
    final newId = row['id'] as String;
    if (source.songs.isNotEmpty) {
      await _db.from('playlist_songs').insert([
        for (final s in source.songs)
          {
            'playlist_id': newId,
            'track_id': s.trackId,
            'title': s.title,
            'artist': s.artist,
            'artwork_url': s.artworkUrl,
            'preview_url': s.previewUrl,
            'store_url': s.storeUrl,
          }
      ]);
    }
    return _fetchOne(newId);
  }

  // ── 내부 헬퍼 ───────────────────────────────────────────

  Future<Set<String>> _myLikedIds() async {
    final rows = await _db
        .from('playlist_likes')
        .select('playlist_id')
        .eq('user_id', _uid);
    return rows.map((r) => r['playlist_id'] as String).toSet();
  }

  Future<Playlist> _fetchOne(String id) async {
    final row = await _db
        .from('playlists')
        .select(_select)
        .eq('id', id)
        .order('position',
            referencedTable: 'playlist_songs', ascending: true)
        .single();
    return _fromRow(row, await _myLikedIds());
  }

  Future<void> _touch(String playlistId) async {
    await _db
        .from('playlists')
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', playlistId);
  }

  Playlist _fromRow(Map<String, dynamic> row, Set<String> likedIds) {
    final songs = (row['playlist_songs'] as List? ?? [])
        .map((s) => Song(
              trackId: (s['track_id'] as num).toInt(),
              title: s['title'] as String,
              artist: s['artist'] as String,
              artworkUrl: s['artwork_url'] as String?,
              previewUrl: s['preview_url'] as String?,
              storeUrl: s['store_url'] as String?,
            ))
        .toList();
    int aggCount(dynamic agg) {
      final list = agg as List? ?? [];
      return list.isNotEmpty
          ? ((list.first as Map)['count'] as num?)?.toInt() ?? 0
          : 0;
    }

    return Playlist(
      id: row['id'] as String,
      title: row['title'] as String,
      ownerId: row['owner_id'] as String,
      ownerNickname:
          (row['profiles'] as Map?)?['nickname'] as String? ?? '알 수 없음',
      emoji: row['emoji'] as String? ?? '🎵',
      songs: songs,
      likeCount: aggCount(row['playlist_likes']),
      forkCount: aggCount(row['forks']),
      likedByMe: likedIds.contains(row['id'] as String),
      forkedFromTitle: row['forked_from_title'] as String?,
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}
