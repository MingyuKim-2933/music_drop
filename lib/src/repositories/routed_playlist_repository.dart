import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import 'playlist_repository.dart';
import 'supabase_playlist_repository.dart';

/// Supabase가 설정되어 있고 로그인 세션이 있으면 원격,
/// 아니면 로컬 목업으로 동작하는 라우팅 리포지토리.
class RoutedPlaylistRepository implements PlaylistRepository {
  final _local = LocalPlaylistRepository();
  final _remote = SupabasePlaylistRepository();

  PlaylistRepository get _active {
    if (SupabaseConfig.isConfigured &&
        Supabase.instance.client.auth.currentUser != null) {
      return _remote;
    }
    return _local;
  }

  @override
  Future<List<Playlist>> fetchMyPlaylists() => _active.fetchMyPlaylists();

  @override
  Future<List<Playlist>> fetchExplore({String? query}) =>
      _active.fetchExplore(query: query);

  @override
  Future<Playlist> updatePlaylist(String id, {String? title, String? emoji}) =>
      _active.updatePlaylist(id, title: title, emoji: emoji);

  @override
  Future<void> reorderMyPlaylists(List<String> orderedIds) =>
      _active.reorderMyPlaylists(orderedIds);

  @override
  Future<Playlist> reorderSongs(String playlistId, List<int> orderedTrackIds) =>
      _active.reorderSongs(playlistId, orderedTrackIds);

  @override
  Future<Playlist> createPlaylist({
    required String title,
    required String emoji,
    required String ownerId,
    required String ownerNickname,
  }) =>
      _active.createPlaylist(
        title: title,
        emoji: emoji,
        ownerId: ownerId,
        ownerNickname: ownerNickname,
      );

  @override
  Future<void> deletePlaylist(String id) => _active.deletePlaylist(id);

  @override
  Future<Playlist> addSong(String playlistId, Song song) =>
      _active.addSong(playlistId, song);

  @override
  Future<Playlist> removeSong(String playlistId, int trackId) =>
      _active.removeSong(playlistId, trackId);

  @override
  Future<Playlist> toggleLike(Playlist playlist) =>
      _active.toggleLike(playlist);

  @override
  Future<Playlist> fork(Playlist source,
          {required String myId, required String myNickname}) =>
      _active.fork(source, myId: myId, myNickname: myNickname);
}
