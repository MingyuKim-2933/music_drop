-- 친구 코드 (닉네임/코드로 친구 추가)
-- Supabase 대시보드 > SQL Editor 에서 실행할 것.

alter table public.profiles add column friend_code text unique;

-- 헷갈리는 문자(0/O/1/I) 제외한 6자리 코드 생성
create or replace function public.gen_friend_code()
returns text
language plpgsql
as $$
declare
  alphabet text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  result text;
  i int;
begin
  loop
    result := '';
    for i in 1..6 loop
      result := result || substr(alphabet, floor(random() * length(alphabet))::int + 1, 1);
    end loop;
    exit when not exists (select 1 from public.profiles where friend_code = result);
  end loop;
  return result;
end;
$$;

-- 기존 사용자 백필
update public.profiles set friend_code = public.gen_friend_code() where friend_code is null;

-- 이후 신규 가입자는 기본값으로 자동 생성
alter table public.profiles alter column friend_code set default public.gen_friend_code();
alter table public.profiles alter column friend_code set not null;

-- 닉네임 검색용 인덱스
create index idx_profiles_nickname on public.profiles(nickname);
