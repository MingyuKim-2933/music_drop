import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/playlist.dart';
import '../models/song.dart';

/// 플레이리스트 데이터 소스.
///
/// 내 플레이리스트는 기기 로컬(SharedPreferences)에 저장하고,
/// "둘러보기"(다른 사람 플레이리스트)·좋아요·퍼가기 집계는
/// 백엔드가 붙기 전까지 목업으로 동작한다.
abstract class PlaylistRepository {
  Future<List<Playlist>> fetchMyPlaylists();
  Future<List<Playlist>> fetchExplore();
  Future<Playlist> createPlaylist({
    required String title,
    required String emoji,
    required String ownerId,
    required String ownerNickname,
  });
  Future<void> deletePlaylist(String id);
  Future<Playlist> addSong(String playlistId, Song song);
  Future<Playlist> removeSong(String playlistId, int trackId);

  /// 좋아요 토글. 토글 후 상태 반환.
  Future<Playlist> toggleLike(Playlist playlist);

  /// 다른 사람 플레이리스트를 내 플레이리스트로 퍼가기(포크).
  Future<Playlist> fork(Playlist source,
      {required String myId, required String myNickname});
}

class LocalPlaylistRepository implements PlaylistRepository {
  static const _kMine = 'playlists_mine';
  static const _kLiked = 'playlists_liked_ids';

  int _seq = 0;

  Future<List<Playlist>> _loadMine(SharedPreferences prefs) async {
    final raw = prefs.getString(_kMine);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((p) => Playlist.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList();
  }

  Future<void> _saveMine(SharedPreferences prefs, List<Playlist> lists) async {
    await prefs.setString(
        _kMine, jsonEncode(lists.map((p) => p.toJson()).toList()));
  }

  @override
  Future<List<Playlist>> fetchMyPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final mine = await _loadMine(prefs);
    mine.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return mine;
  }

  @override
  Future<Playlist> createPlaylist({
    required String title,
    required String emoji,
    required String ownerId,
    required String ownerNickname,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final mine = await _loadMine(prefs);
    final playlist = Playlist(
      id: 'local:${DateTime.now().millisecondsSinceEpoch}:${_seq++}',
      title: title,
      ownerId: ownerId,
      ownerNickname: ownerNickname,
      emoji: emoji,
      updatedAt: DateTime.now(),
    );
    mine.add(playlist);
    await _saveMine(prefs, mine);
    return playlist;
  }

  @override
  Future<void> deletePlaylist(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final mine = await _loadMine(prefs);
    mine.removeWhere((p) => p.id == id);
    await _saveMine(prefs, mine);
  }

  @override
  Future<Playlist> addSong(String playlistId, Song song) async {
    return _update(playlistId, (p) {
      if (p.songs.any((s) => s.trackId == song.trackId)) return p;
      return p.copyWith(
        songs: [...p.songs, song],
        updatedAt: DateTime.now(),
      );
    });
  }

  @override
  Future<Playlist> removeSong(String playlistId, int trackId) async {
    return _update(playlistId, (p) {
      return p.copyWith(
        songs: p.songs.where((s) => s.trackId != trackId).toList(),
        updatedAt: DateTime.now(),
      );
    });
  }

  Future<Playlist> _update(
      String playlistId, Playlist Function(Playlist) transform) async {
    final prefs = await SharedPreferences.getInstance();
    final mine = await _loadMine(prefs);
    final index = mine.indexWhere((p) => p.id == playlistId);
    if (index == -1) throw Exception('플레이리스트를 찾을 수 없어요');
    mine[index] = transform(mine[index]);
    await _saveMine(prefs, mine);
    return mine[index];
  }

  @override
  Future<Playlist> toggleLike(Playlist playlist) async {
    final prefs = await SharedPreferences.getInstance();
    final liked = (prefs.getStringList(_kLiked) ?? []).toSet();
    final nowLiked = !liked.contains(playlist.id);
    if (nowLiked) {
      liked.add(playlist.id);
    } else {
      liked.remove(playlist.id);
    }
    await prefs.setStringList(_kLiked, liked.toList());
    // 목업: 좋아요 수는 로컬에서만 증감. 백엔드 도입 시 서버 집계로 교체.
    return playlist.copyWith(
      likedByMe: nowLiked,
      likeCount: playlist.likeCount + (nowLiked ? 1 : -1),
    );
  }

  @override
  Future<Playlist> fork(Playlist source,
      {required String myId, required String myNickname}) async {
    final prefs = await SharedPreferences.getInstance();
    final mine = await _loadMine(prefs);
    final forked = Playlist(
      id: 'local:${DateTime.now().millisecondsSinceEpoch}:${_seq++}',
      title: source.title,
      ownerId: myId,
      ownerNickname: myNickname,
      emoji: source.emoji,
      songs: source.songs,
      forkedFromTitle: '${source.ownerNickname}님의 ${source.title}',
      updatedAt: DateTime.now(),
    );
    mine.add(forked);
    await _saveMine(prefs, mine);
    return forked;
  }

  // ── 둘러보기 목업 (백엔드 도입 시 서버 데이터로 교체) ──

  @override
  Future<List<Playlist>> fetchExplore() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final prefs = await SharedPreferences.getInstance();
    final liked = (prefs.getStringList(_kLiked) ?? []).toSet();
    return _explorePlaylists
        .map((p) => liked.contains(p.id)
            ? p.copyWith(likedByMe: true, likeCount: p.likeCount + 1)
            : p)
        .toList();
  }

  static final _explorePlaylists = [
    Playlist(
      id: 'explore:1',
      title: '새벽 감성 발라드',
      ownerId: 'mock:jiwoo',
      ownerNickname: '지우',
      emoji: '🌙',
      likeCount: 128,
      updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
      songs: const [
        Song(
          trackId: 1725572560,
          title: '한 페이지가 될 수 있게',
          artist: 'DAY6',
          artworkUrl:
              'https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/60/22/32/602232a3-5f4d-2b25-a7ac-2807e7e1554e/196922729539_Cover.jpg/600x600bb.jpg',
        ),
        Song(
          trackId: 1440818346,
          title: '너였다면',
          artist: '정승환',
          artworkUrl: null,
        ),
        Song(trackId: 3, title: '무제', artist: 'G-DRAGON', artworkUrl: null),
      ],
    ),
    Playlist(
      id: 'explore:2',
      title: '출근길 텐션업 K-POP',
      ownerId: 'mock:minjun',
      ownerNickname: '민준',
      emoji: '🔥',
      likeCount: 342,
      updatedAt: DateTime.now().subtract(const Duration(hours: 8)),
      songs: const [
        Song(trackId: 11, title: 'Supernova', artist: 'aespa', artworkUrl: null),
        Song(trackId: 12, title: 'APT.', artist: '로제, Bruno Mars', artworkUrl: null),
        Song(trackId: 13, title: 'Magnetic', artist: '아일릿', artworkUrl: null),
        Song(trackId: 14, title: 'How Sweet', artist: 'NewJeans', artworkUrl: null),
      ],
    ),
    Playlist(
      id: 'explore:3',
      title: '공부할 때 듣는 로파이',
      ownerId: 'mock:seoyeon',
      ownerNickname: '서연',
      emoji: '📚',
      likeCount: 87,
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      songs: const [
        Song(trackId: 21, title: 'Snowman', artist: 'WYS', artworkUrl: null),
        Song(trackId: 22, title: 'Daydream', artist: 'potsu', artworkUrl: null),
      ],
    ),
  ];
}
