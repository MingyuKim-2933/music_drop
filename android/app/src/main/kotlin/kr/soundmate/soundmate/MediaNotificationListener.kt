package kr.soundmate.soundmate

import android.service.notification.NotificationListenerService

/**
 * MediaSessionManager.getActiveSessions() 호출 자격을 얻기 위한
 * NotificationListenerService. 실제 로직은 MediaSessionTracker에 있다.
 *
 * 사용자가 시스템 설정에서 이 컴포넌트에 "알림 접근"을 허용하면
 * 앱이 기기 내 음악 앱들의 재생 세션을 읽을 수 있게 된다.
 */
class MediaNotificationListener : NotificationListenerService()
