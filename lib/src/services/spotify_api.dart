import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/track.dart';
import 'spotify_auth.dart';

/// Spotify Web API 호출 담당.
class SpotifyApi {
  SpotifyApi(this._auth);

  final SpotifyAuth _auth;

  /// 지금 재생 중인 트랙. 재생 중이 아니면 최근 재생 트랙, 둘 다 없으면 null.
  Future<NowPlaying?> fetchNowPlaying() async {
    final token = await _auth.accessToken();
    if (token == null) return null;

    final current = await _get(
      'https://api.spotify.com/v1/me/player/currently-playing',
      token,
    );
    if (current != null && current['item'] != null) {
      return _fromTrackJson(
        current['item'] as Map<String, dynamic>,
        isPlaying: current['is_playing'] == true,
      );
    }

    final recent = await _get(
      'https://api.spotify.com/v1/me/player/recently-played?limit=1',
      token,
    );
    final items = recent?['items'] as List?;
    if (items == null || items.isEmpty) return null;
    return _fromTrackJson(
      (items.first as Map<String, dynamic>)['track'] as Map<String, dynamic>,
      isPlaying: false,
    );
  }

  Future<Map<String, dynamic>?> _get(String url, String token) async {
    final res = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200 || res.body.isEmpty) return null;
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  NowPlaying _fromTrackJson(Map<String, dynamic> track,
      {required bool isPlaying}) {
    final artists = (track['artists'] as List?)
            ?.map((a) => (a as Map<String, dynamic>)['name'] as String)
            .join(', ') ??
        '알 수 없는 아티스트';
    final images = (track['album']?['images'] as List?) ?? [];
    return NowPlaying(
      title: track['name'] as String? ?? '알 수 없는 곡',
      artist: artists,
      albumArtUrl: images.isNotEmpty
          ? (images.first as Map<String, dynamic>)['url'] as String?
          : null,
      source: MusicSource.spotify,
      isPlaying: isPlaying,
      updatedAt: DateTime.now(),
    );
  }
}
