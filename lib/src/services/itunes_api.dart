import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/song.dart';

/// iTunes Search API — 무료, 인증 불필요.
/// 곡 검색 + 앨범아트 + 30초 미리듣기 URL 제공.
/// https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/iTuneSearchAPI/
class ItunesApi {
  Future<List<Song>> searchSongs(String query, {int limit = 25}) async {
    if (query.trim().isEmpty) return [];
    final uri = Uri.https('itunes.apple.com', '/search', {
      'term': query,
      'country': 'KR',
      'media': 'music',
      'entity': 'song',
      'limit': '$limit',
    });
    final res = await http.get(uri);
    if (res.statusCode != 200) return [];
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final results = body['results'] as List? ?? [];
    return results
        .whereType<Map<String, dynamic>>()
        .where((r) => r['trackId'] != null)
        .map(Song.fromItunes)
        .toList();
  }
}
