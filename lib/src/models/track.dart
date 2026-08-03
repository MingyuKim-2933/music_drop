/// 재생 소스 (어느 스트리밍 앱에서 재생 중인지)
enum MusicSource {
  spotify('Spotify'),
  melon('멜론'),
  genie('지니뮤직'),
  flo('FLO'),
  youtubeMusic('유튜브 뮤직'),
  vibe('VIBE'),
  bugs('벅스'),
  unknown('기타');

  const MusicSource(this.label);
  final String label;

  /// Android 패키지명 → 소스 매핑
  static MusicSource fromPackage(String pkg) {
    switch (pkg) {
      case 'com.spotify.music':
        return MusicSource.spotify;
      case 'com.iloen.melon':
        return MusicSource.melon;
      case 'com.ktmusic.geniemusic':
        return MusicSource.genie;
      case 'skplanet.musicmate':
        return MusicSource.flo;
      case 'com.google.android.apps.youtube.music':
        return MusicSource.youtubeMusic;
      case 'com.naver.vibe':
        return MusicSource.vibe;
      case 'com.neowiz.android.bugs':
        return MusicSource.bugs;
      default:
        return MusicSource.unknown;
    }
  }
}

/// 지금 재생 중인(또는 최근 재생한) 트랙 정보
class NowPlaying {
  final String title;
  final String artist;
  final String? albumArtUrl;
  final MusicSource source;
  final bool isPlaying;
  final DateTime updatedAt;

  const NowPlaying({
    required this.title,
    required this.artist,
    this.albumArtUrl,
    required this.source,
    required this.isPlaying,
    required this.updatedAt,
  });

  NowPlaying copyWith({bool? isPlaying}) => NowPlaying(
        title: title,
        artist: artist,
        albumArtUrl: albumArtUrl,
        source: source,
        isPlaying: isPlaying ?? this.isPlaying,
        updatedAt: updatedAt,
      );

  @override
  String toString() => '$artist - $title (${source.label})';
}
