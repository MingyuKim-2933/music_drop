/// 친구에게 받은 이모지 반응
class Reaction {
  final String id;
  final String fromNickname;
  final String emoji;
  final String? trackTitle;
  final DateTime createdAt;

  const Reaction({
    required this.id,
    required this.fromNickname,
    required this.emoji,
    this.trackTitle,
    required this.createdAt,
  });
}
