import 'package:flutter/material.dart';

import '../models/track.dart';

/// 소스별 브랜드 색
Color sourceColor(MusicSource source) {
  switch (source) {
    case MusicSource.spotify:
      return const Color(0xFF1DB954);
    case MusicSource.melon:
      return const Color(0xFF00CD3C);
    case MusicSource.genie:
      return const Color(0xFF3498FF);
    case MusicSource.flo:
      return const Color(0xFF3F3FFF);
    case MusicSource.youtubeMusic:
      return const Color(0xFFFF0000);
    case MusicSource.vibe:
      return const Color(0xFFEE1171);
    case MusicSource.bugs:
      return const Color(0xFFFF3B28);
    case MusicSource.unknown:
      return Colors.grey;
  }
}

/// 내 "지금 듣는 중" 대형 카드
class NowPlayingCard extends StatelessWidget {
  const NowPlayingCard({super.key, required this.nowPlaying});

  final NowPlaying? nowPlaying;

  @override
  Widget build(BuildContext context) {
    final np = nowPlaying;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: np == null
              ? [const Color(0xFF1D1830), const Color(0xFF141021)]
              : [
                  sourceColor(np.source).withValues(alpha: 0.35),
                  const Color(0xFF141021),
                ],
        ),
      ),
      child: np == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('아직 감상 기록이 없어요',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  '설정에서 Spotify를 연결하거나\n(Android) 알림 접근을 허용해 주세요',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.white54),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      np.isPlaying ? Icons.graphic_eq : Icons.history,
                      size: 16,
                      color: sourceColor(np.source),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      np.isPlaying
                          ? '지금 ${np.source.label}에서 듣는 중'
                          : '최근에 ${np.source.label}에서 들음',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: np.albumArtUrl != null
                          ? Image.network(np.albumArtUrl!,
                              width: 64, height: 64, fit: BoxFit.cover)
                          : Container(
                              width: 64,
                              height: 64,
                              color: Colors.white10,
                              child: const Icon(Icons.music_note, size: 30),
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            np.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            np.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
