-- 친구 코드 (닉네임/코드로 친구 추가)
-- Supabase 대시보드 > SQL Editor 에서 실행할 것.
-- 혼동되는 문자(0, 1)는 X, Y로 치환해 7자리 코드를 만든다.

alter table public.profiles add column friend_code text unique;

-- 기존 사용자 백필
update public.profiles
set friend_code = upper(translate(substr(md5(random()::text || id::text), 1, 7), '01', 'xy'));

-- 신규 가입자는 기본값으로 자동 생성
alter table public.profiles
  alter column friend_code set default upper(translate(substr(md5(random()::text), 1, 7), '01', 'xy'));

alter table public.profiles alter column friend_code set not null;

-- 닉네임 검색용 인덱스
create index idx_profiles_nickname on public.profiles(nickname);
