# 국내외 스트리밍 API 조사 (2026-08-04)

각 서비스에서 사용자의 실시간/최근 감상 데이터를 조회할 수 있는지 조사한 결과.

## 결론

| 서비스 | 공식 API | 적용 방법 |
|---|---|---|
| Spotify | ✅ 있음 | Web API `currently-playing` / `recently-played` (OAuth PKCE) — 양 플랫폼 |
| 유튜브 뮤직 | ❌ 없음 | 감상 기록은 Google Takeout뿐 → Android 재생 감지로 우회 |
| 멜론 | ❌ 없음 | 비공식 차트 크롤링만 존재, 개인 재생기록 접근 불가 |
| 지니뮤직 | ❌ 없음 | 상동 |
| FLO | ❌ 없음 | 상동 |

## 우회 전략: Android MediaSessionManager

- 알림 접근 권한(NotificationListenerService 자격)으로 기기 내 모든 음악 앱의 "지금 재생 중" 메타데이터 조회 가능 — 실제 Airbuds류 앱들이 쓰는 방식
- 감지 대상 패키지: `com.iloen.melon`(멜론), `com.ktmusic.geniemusic`(지니), `skplanet.musicmate`(FLO), `com.google.android.apps.youtube.music`, `com.spotify.music`, `com.naver.vibe`, `com.neowiz.android.bugs`
- **iOS는 불가** (샌드박스) → Spotify 연동만, 추후 Apple Music(MusicKit) 추가

## 참고 링크

- [Spotify: Get Currently Playing Track](https://developer.spotify.com/documentation/web-api/reference/get-the-users-currently-playing-track)
- [Spotify: Get Recently Played](https://developer.spotify.com/documentation/web-api/reference/get-recently-played)
- [ytmusicapi (비공식 파이썬)](https://github.com/sigma67/ytmusicapi)
