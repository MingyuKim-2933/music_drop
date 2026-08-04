/// 닉네임/친구코드 검색 결과
class UserSearchResult {
  final String id;
  final String nickname;
  final String emoji;
  final String friendCode;
  final bool alreadyFriend;

  const UserSearchResult({
    required this.id,
    required this.nickname,
    this.emoji = '🎧',
    required this.friendCode,
    this.alreadyFriend = false,
  });

  UserSearchResult copyWith({bool? alreadyFriend}) => UserSearchResult(
        id: id,
        nickname: nickname,
        emoji: emoji,
        friendCode: friendCode,
        alreadyFriend: alreadyFriend ?? this.alreadyFriend,
      );
}
