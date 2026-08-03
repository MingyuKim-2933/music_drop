import 'dart:io';

import 'package:flutter/services.dart';

import '../models/track.dart';

/// Android 전용: 네이티브 MediaSession 리스너와 통신하는 채널.
///
/// 멜론/지니/FLO/유튜브뮤직 등은 공개 API가 없으므로,
/// Android 알림 접근 권한(MediaSessionManager)으로 기기에서 직접
/// "지금 재생 중" 메타데이터를 읽는다. iOS에서는 동작하지 않는다.
class MediaSessionChannel {
  static const _method = MethodChannel('soundmate/media');
  static const _events = EventChannel('soundmate/media_events');

  static bool get isSupported => Platform.isAndroid;

  /// 알림 접근 권한이 허용되어 있는지 확인.
  static Future<bool> hasPermission() async {
    if (!isSupported) return false;
    final granted = await _method.invokeMethod<bool>('hasNotificationAccess');
    return granted ?? false;
  }

  /// 시스템 설정의 알림 접근 허용 화면을 연다.
  static Future<void> openPermissionSettings() async {
    if (!isSupported) return;
    await _method.invokeMethod('openNotificationAccessSettings');
  }

  /// 기기 내 음악 앱들의 재생 상태 스트림.
  static Stream<NowPlaying?> nowPlayingStream() {
    if (!isSupported) return const Stream.empty();
    return _events.receiveBroadcastStream().map((event) {
      if (event == null) return null;
      final map = Map<String, dynamic>.from(event as Map);
      return NowPlaying(
        title: map['title'] as String? ?? '알 수 없는 곡',
        artist: map['artist'] as String? ?? '알 수 없는 아티스트',
        albumArtUrl: null, // 네이티브 아트워크는 추후 바이트 전송으로 확장
        source: MusicSource.fromPackage(map['package'] as String? ?? ''),
        isPlaying: map['isPlaying'] as bool? ?? false,
        updatedAt: DateTime.now(),
      );
    });
  }
}
