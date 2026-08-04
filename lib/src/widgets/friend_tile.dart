import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/friend.dart';
import '../repositories/friends_repository.dart';
import 'now_playing_card.dart';

/// 친구 피드의 한 줄
class FriendTile extends StatelessWidget {
  const FriendTile({
    super.key,
    required this.friend,
    this.sameSong = false,
  });

  final Friend friend;

  /// 나와 같은 곡을 지금 함께 듣는 중이면 강조 표시
  final bool sameSong;

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final np = friend.nowPlaying;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: sameSong ? const Color(0xFF241C3D) : const Color(0xFF1A1526),
        borderRadius: BorderRadius.circular(18),
        border: sameSong
            ? Border.all(color: const Color(0xFF7C4DFF), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white10,
            child: Text(friend.emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      friend.nickname,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 6),
                    if (sameSong)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C4DFF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '🎧 같이 듣는 중',
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      )
                    else if (np != null)
                      Text(
                        np.isPlaying ? '듣는중' : _timeAgo(np.updatedAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: np.isPlaying
                              ? sourceColor(np.source)
                              : Colors.white38,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                if (np == null)
                  Text('아직 조용해요 💤',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.white38))
                else
                  Row(
                    children: [
                      if (np.isPlaying) ...[
                        Icon(Icons.graphic_eq,
                            size: 14, color: sourceColor(np.source)),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          '${np.title} · ${np.artist}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.white70),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: sourceColor(np.source).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          np.source.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            color: sourceColor(np.source),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Text('🫶', style: TextStyle(fontSize: 18)),
            onPressed: np == null
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await context.read<FriendsRepository>().sendReaction(
                            toUserId: friend.id,
                            trackTitle: np.title,
                          );
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('${friend.nickname}님에게 🫶 보냈어요!'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    } catch (_) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('반응 전송에 실패했어요')),
                      );
                    }
                  },
          ),
        ],
      ),
    );
  }
}
