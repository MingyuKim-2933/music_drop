import '../models/friend.dart';
import '../models/track.dart';
import '../services/contacts_service.dart';

/// 연락처 ↔ 앱 사용자 매칭 결과
class ContactMatch {
  final PhoneContact contact;
  final bool isAppUser;

  const ContactMatch({required this.contact, required this.isAppUser});
}

/// 친구 피드 데이터 소스.
///
/// 지금은 목업 구현만 있고, 백엔드(Firebase/자체 서버)가 준비되면
/// 이 인터페이스를 구현한 원격 리포지토리로 교체한다.
abstract class FriendsRepository {
  Future<List<Friend>> fetchFriends();

  /// 연락처 목록을 서버에 보내 앱 사용자인지 매칭.
  /// (실서비스에서는 전화번호를 해시해서 전송할 것)
  Future<List<ContactMatch>> matchContacts(List<PhoneContact> contacts);

  /// 앱을 쓰고 있는 연락처를 친구로 추가
  Future<void> addFriend(PhoneContact contact);
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
      ..._added,
    ];
  }

  final List<Friend> _added = [];

  @override
  Future<List<ContactMatch>> matchContacts(List<PhoneContact> contacts) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    // 목업: 전화번호 숫자 합이 3의 배수면 앱 사용자라고 가정.
    // 실제로는 번호 해시를 서버로 보내 가입자와 매칭한다.
    return [
      for (final c in contacts)
        ContactMatch(
          contact: c,
          isAppUser: c.phone.runes
                      .where((r) => r >= 0x30 && r <= 0x39)
                      .fold<int>(0, (sum, r) => sum + (r - 0x30)) %
                  3 ==
              0,
        ),
    ];
  }

  @override
  Future<void> addFriend(PhoneContact contact) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _added.add(Friend(
      id: 'contact:${contact.phone}',
      nickname: contact.name,
      emoji: '🎵',
    ));
  }
}
