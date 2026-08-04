import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// 친구가 보낸 이모지 반응을 실시간으로 받아 알림으로 띄운다.
///
/// Supabase Realtime(reactions insert 구독) + 로컬 알림 조합이라
/// 앱이 실행 중일 때 동작한다. 앱 종료 상태의 OS 푸시는
/// FCM 연동(Firebase 프로젝트 필요)으로 확장 예정.
class ReactionNotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  RealtimeChannel? _channel;
  bool _initialized = false;

  Future<void> start() async {
    if (!SupabaseConfig.isConfigured) return;
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return;

    if (!_initialized) {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      // Android 13+ 알림 권한 요청
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _initialized = true;
    }

    _channel?.unsubscribe();
    _channel = client
        .channel('reactions:$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'reactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'to_user',
            value: uid,
          ),
          callback: _onReaction,
        )
        .subscribe();
  }

  Future<void> _onReaction(PostgresChangePayload payload) async {
    final record = payload.newRecord;
    final emoji = record['emoji'] as String? ?? '🫶';
    final trackTitle = record['track_title'] as String?;
    final fromUser = record['from_user'] as String?;

    // 보낸 사람 닉네임 조회 (실패해도 알림은 띄운다)
    var nickname = '친구';
    if (fromUser != null) {
      try {
        final row = await Supabase.instance.client
            .from('profiles')
            .select('nickname')
            .eq('id', fromUser)
            .single();
        nickname = row['nickname'] as String? ?? nickname;
      } catch (_) {}
    }

    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '$emoji $nickname님의 반응',
      body: trackTitle != null
          ? '$nickname님이 "$trackTitle" 듣는 걸 좋아해요!'
          : '$nickname님이 반응을 보냈어요!',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'reactions',
          '이모지 반응',
          channelDescription: '친구가 보낸 이모지 반응 알림',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  void stop() {
    _channel?.unsubscribe();
    _channel = null;
  }
}
