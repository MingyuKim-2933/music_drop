# Supabase 세팅 가이드

백엔드는 **Supabase**로 결정 (2026-08-04). 코드 연동은 완료 상태이며, 아래만 하면 실데이터로 전환된다.

## 1. 프로젝트 생성 (약 2분)

- [x] https://supabase.com/dashboard 접속 → 가입/로그인
- [x] `New project` → 이름 `soundmate`, 리전 **Northeast Asia (Seoul)** 선택
- [x] DB 비밀번호는 따로 보관 (앱에서는 안 씀)

## 2. 스키마 적용

- [x] 대시보드 왼쪽 `SQL Editor` → `New query`
- [x] 저장소의 `supabase/migrations/20260804000000_init.sql` 내용 전체 붙여넣기 → `Run`
- 생성되는 것: profiles(자동 생성 트리거 포함), now_playing, friendships, playlists, playlist_songs, playlist_likes + RLS 정책 전부

## 3. 키 연결

- [x] `Settings > API Keys` 에서 **Project URL**과 **Publishable key** 복사
- [x] `lib/src/config/supabase_config.dart` 의 `url`, `publishableKey` 교체 (2026-08-04)

## 4. 인증 설정

- [x] (개발 중 편의) `Authentication > Sign In / Providers > Email` 에서 **Confirm email 끄기**
  - ⚠️ 출시 전에 다시 켜고 메일 템플릿 설정할 것
- [ ] (선택) 카카오 연동: 카카오 개발자 콘솔에서 **OpenID Connect 활성화** → Supabase `Authentication > Providers > Kakao` 에 REST API 키/시크릿 입력
- 네이버는 Supabase 미지원 → 추후 Edge Function으로 커스텀 JWT 발급 (지금은 로컬 세션으로 동작)

## 동작 방식

- 키가 설정되면: 이메일 가입/로그인 = Supabase Auth, 플레이리스트/좋아요/퍼가기 = 실서버 (다른 유저와 실제 공유됨)
- 키가 없으면: 기존 로컬 목업으로 폴백 (`RoutedPlaylistRepository`가 자동 판단)

## 남은 백엔드 작업

- [ ] 감상 상태(now_playing) 업로드 + 친구 피드 실데이터
- [ ] 연락처 번호 해시 매칭 (profiles.phone_hash)
- [ ] 네이버 로그인 Edge Function
- [ ] 초대 ref 추적 저장
