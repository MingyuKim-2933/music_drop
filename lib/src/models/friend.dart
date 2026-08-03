import 'track.dart';

/// 친구 한 명의 프로필 + 현재/최근 감상 정보
class Friend {
  final String id;
  final String nickname;
  final String emoji; // 프로필 대신 쓰는 이모지 아바타
  final NowPlaying? nowPlaying;

  const Friend({
    required this.id,
    required this.nickname,
    required this.emoji,
    this.nowPlaying,
  });
}
