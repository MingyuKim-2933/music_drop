import 'song.dart';

class Playlist {
  final String id;
  final String title;
  final String ownerId;
  final String ownerNickname;
  final String emoji; // 커버 대신 쓰는 이모지
  final List<Song> songs;
  final int likeCount;
  final bool likedByMe;
  final String? forkedFromTitle; // 퍼온 플레이리스트 원본 제목
  final DateTime updatedAt;

  const Playlist({
    required this.id,
    required this.title,
    required this.ownerId,
    required this.ownerNickname,
    this.emoji = '🎵',
    this.songs = const [],
    this.likeCount = 0,
    this.likedByMe = false,
    this.forkedFromTitle,
    required this.updatedAt,
  });

  Playlist copyWith({
    String? title,
    String? emoji,
    List<Song>? songs,
    int? likeCount,
    bool? likedByMe,
    DateTime? updatedAt,
  }) =>
      Playlist(
        id: id,
        title: title ?? this.title,
        ownerId: ownerId,
        ownerNickname: ownerNickname,
        emoji: emoji ?? this.emoji,
        songs: songs ?? this.songs,
        likeCount: likeCount ?? this.likeCount,
        likedByMe: likedByMe ?? this.likedByMe,
        forkedFromTitle: forkedFromTitle,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'ownerId': ownerId,
        'ownerNickname': ownerNickname,
        'emoji': emoji,
        'songs': songs.map((s) => s.toJson()).toList(),
        'likeCount': likeCount,
        'likedByMe': likedByMe,
        'forkedFromTitle': forkedFromTitle,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
        id: json['id'] as String,
        title: json['title'] as String,
        ownerId: json['ownerId'] as String,
        ownerNickname: json['ownerNickname'] as String,
        emoji: json['emoji'] as String? ?? '🎵',
        songs: (json['songs'] as List? ?? [])
            .map((s) => Song.fromJson(Map<String, dynamic>.from(s as Map)))
            .toList(),
        likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
        likedByMe: json['likedByMe'] as bool? ?? false,
        forkedFromTitle: json['forkedFromTitle'] as String?,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
