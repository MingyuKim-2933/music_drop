# MUSE

한국판 Airbuds — 친구들이 지금 무슨 노래를 듣는지 실시간으로 공유하는 소셜 음악 앱.
Flutter로 작성되어 Android / iOS를 모두 지원한다.

## 스트리밍 서비스별 감상 데이터 수집 방식

| 서비스 | 방식 | 플랫폼 |
|---|---|---|
| Spotify | 공식 Web API (`currently-playing` / `recently-played`, OAuth PKCE) | Android + iOS |
| 멜론 / 지니뮤직 / FLO / 유튜브뮤직 / VIBE / 벅스 | 공개 API 없음 → Android **알림 접근 권한 + MediaSessionManager**로 기기에서 직접 재생 메타데이터 감지 | Android 전용 |

iOS는 서드파티 앱의 재생 정보를 읽을 방법이 없어(샌드박스 정책) Spotify 연동만 동작한다.
Apple Music은 MusicKit으로 확장 가능(미구현).

## 실행 전 설정

1. **Spotify 개발자 등록**
   - https://developer.spotify.com/dashboard 에서 앱 생성
   - Redirect URI에 `muse://callback` 추가
   - `lib/src/services/spotify_auth.dart`의 `clientId`를 발급받은 Client ID로 교체

2. **빌드 환경** (`flutter doctor`로 확인)
   - Android: Android Studio(SDK) 설치
   - iOS: Xcode 전체 설치 + CocoaPods (`brew install cocoapods`)

3. **실행**
   ```bash
   flutter pub get
   flutter run          # 연결된 기기/에뮬레이터에서 실행
   flutter build apk    # Android 빌드
   flutter build ios    # iOS 빌드 (서명 설정 필요)
   ```

4. **Android에서 멜론/지니/FLO 감지 활성화**
   - 앱 실행 → 설정 → "멜론 · 지니 · FLO · 유튜브뮤직" → 허용하기
   - 시스템 설정에서 "MUSE"에 알림 접근 허용

## 구조

```
lib/
├── main.dart                        # 엔트리, 테마, Provider 구성
└── src/
    ├── models/                      # NowPlaying, Friend, MusicSource
    ├── services/
    │   ├── spotify_auth.dart        # OAuth PKCE + 토큰 갱신
    │   ├── spotify_api.dart         # currently-playing / recently-played
    │   ├── media_session_channel.dart  # Android 네이티브 채널 (Dart 측)
    │   └── now_playing_service.dart # 소스 통합 (네이티브 > Spotify 폴링)
    ├── repositories/
    │   └── friends_repository.dart  # 친구 피드 (현재 목업, 백엔드 교체 지점)
    ├── screens/                     # 홈(피드), 설정
    └── widgets/                     # NowPlayingCard, FriendTile

android/app/src/main/kotlin/kr/muse/muse/
├── MainActivity.kt                  # MethodChannel + EventChannel
├── MediaNotificationListener.kt     # 알림 접근 자격용 서비스
└── MediaSessionTracker.kt           # 음악 앱 MediaSession 구독 → Flutter로 전송
```

## 다음 단계 (미구현)

- 백엔드: 친구 관계 + 실시간 감상 상태 동기화 (Firebase/Supabase 권장) — `FriendsRepository` 구현체 교체
- 내 감상 상태 서버 업로드 (현재는 로컬 표시만)
- Apple Music 연동 (iOS 커버리지 확대)
- 앨범 아트: Android MediaMetadata 비트맵 전송, 또는 곡명 기반 iTunes Search API 매칭
- 홈 화면 위젯 (Airbuds의 핵심 UX)
- 이모지 반응 실제 전송
