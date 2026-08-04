/// 플레이리스트에 담기는 곡 (iTunes Search API 메타데이터).
/// 음원 파일은 저장하지 않는다 — 메타데이터와 외부 링크만.
class Song {
  final int trackId; // iTunes trackId
  final String title;
  final String artist;
  final String? artworkUrl;
  final String? previewUrl; // 30초 미리듣기 (사용 안 해도 보관)
  final String? storeUrl; // Apple Music/iTunes 링크

  const Song({
    required this.trackId,
    required this.title,
    required this.artist,
    this.artworkUrl,
    this.previewUrl,
    this.storeUrl,
  });

  Map<String, dynamic> toJson() => {
        'trackId': trackId,
        'title': title,
        'artist': artist,
        'artworkUrl': artworkUrl,
        'previewUrl': previewUrl,
        'storeUrl': storeUrl,
      };

  factory Song.fromJson(Map<String, dynamic> json) => Song(
        trackId: json['trackId'] as int,
        title: json['title'] as String,
        artist: json['artist'] as String,
        artworkUrl: json['artworkUrl'] as String?,
        previewUrl: json['previewUrl'] as String?,
        storeUrl: json['storeUrl'] as String?,
      );

  /// iTunes 검색 결과 JSON에서 생성
  factory Song.fromItunes(Map<String, dynamic> json) {
    final artwork100 = json['artworkUrl100'] as String?;
    return Song(
      trackId: (json['trackId'] as num).toInt(),
      title: json['trackName'] as String? ?? '알 수 없는 곡',
      artist: json['artistName'] as String? ?? '알 수 없는 아티스트',
      // 100x100 → 600x600 고화질로 교체
      artworkUrl: artwork100?.replaceAll('100x100', '600x600'),
      previewUrl: json['previewUrl'] as String?,
      storeUrl: json['trackViewUrl'] as String?,
    );
  }
}
