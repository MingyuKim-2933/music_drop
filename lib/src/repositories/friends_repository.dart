import '../models/friend.dart';
import '../models/track.dart';

/// 친구 피드 데이터 소스.
///
/// 지금은 목업 구현만 있고, 백엔드(Firebase/자체 서버)가 준비되면
/// 이 인터페이스를 구현한 원격 리포지토리로 교체한다.
abstract class FriendsRepository {
  Future<List<Friend>> fetchFriends();
}

class MockFriendsRepository implements FriendsRepository {
  @override
  Future<List<Friend>> fetchFriends() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final now = DateTime.now();
    return [
      Friend(
        id: '1',
        nickname: '지우',
        emoji: '🐰',
        nowPlaying: NowPlaying(
          title: 'Supernova',
          artist: 'aespa',
          albumArtUrl: null,
          source: MusicSource.melon,
          isPlaying: true,
          updatedAt: now.subtract(const Duration(minutes: 1)),
        ),
      ),
      Friend(
        id: '2',
        nickname: '민준',
        emoji: '🔥',
        nowPlaying: NowPlaying(
          title: 'Die With A Smile',
          artist: 'Lady Gaga, Bruno Mars',
          albumArtUrl: null,
          source: MusicSource.spotify,
          isPlaying: true,
          updatedAt: now.subtract(const Duration(minutes: 3)),
        ),
      ),
      Friend(
        id: '3',
        nickname: '서연',
        emoji: '🌙',
        nowPlaying: NowPlaying(
          title: '한 페이지가 될 수 있게',
          artist: 'DAY6',
          albumArtUrl: null,
          source: MusicSource.youtubeMusic,
          isPlaying: false,
          updatedAt: now.subtract(const Duration(hours: 2)),
        ),
      ),
      Friend(
        id: '4',
        nickname: '하준',
        emoji: '🎧',
        nowPlaying: NowPlaying(
          title: 'APT.',
          artist: '로제, Bruno Mars',
          albumArtUrl: null,
          source: MusicSource.flo,
          isPlaying: false,
          updatedAt: now.subtract(const Duration(hours: 5)),
        ),
      ),
      const Friend(id: '5', nickname: '유나', emoji: '🫧'),
    ];
  }
}
