-- reactions 테이블 실시간 구독 활성화
-- (Supabase Realtime은 publication에 추가된 테이블만 변경 이벤트를 전송한다)
-- Supabase 대시보드 > SQL Editor 에서 실행할 것.

alter publication supabase_realtime add table public.reactions;
