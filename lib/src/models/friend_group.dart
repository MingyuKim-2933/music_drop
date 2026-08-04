/// 친구 그룹 (피드를 그룹별로 나눠 보기 위한 묶음)
class FriendGroup {
  final String id;
  final String name;
  final String emoji;
  final Set<String> memberIds;

  const FriendGroup({
    required this.id,
    required this.name,
    this.emoji = '👥',
    this.memberIds = const {},
  });

  FriendGroup copyWith({String? name, String? emoji, Set<String>? memberIds}) =>
      FriendGroup(
        id: id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        memberIds: memberIds ?? this.memberIds,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'memberIds': memberIds.toList(),
      };

  factory FriendGroup.fromJson(Map<String, dynamic> json) => FriendGroup(
        id: json['id'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String? ?? '👥',
        memberIds:
            ((json['memberIds'] as List?) ?? []).map((e) => e as String).toSet(),
      );
}
