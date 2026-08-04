-- 출시 전 보안 강화 + 계정 삭제
-- Supabase 대시보드 > SQL Editor 에서 실행할 것.
-- (함수는 $$ 대신 작은따옴표 본문을 써서 붙여넣기 사고를 피한다)

-- ── 1. 감상 기록: 친구에게만 공개 ────────────────────────
drop policy if exists "now_playing_select" on public.now_playing;

create policy "now_playing_select" on public.now_playing
  for select to authenticated
  using (
    user_id = auth.uid()
    or exists (
      select 1 from public.friendships f
      where f.user_id = auth.uid() and f.friend_id = now_playing.user_id
    )
  );

-- ── 2. 전화번호 해시: 아무도 직접 읽지 못하게 ─────────────
-- 등록 여부만 노출하는 파생 컬럼
alter table public.profiles
  add column has_phone boolean generated always as (phone_hash is not null) stored;

-- 연락처 매칭은 "내가 보낸 해시와 일치하는 것만" 돌려주는 함수로만 가능
create or replace function public.match_contacts(hashes text[])
returns table (id uuid, phone_hash text)
language sql
security definer
set search_path = public
as 'select p.id, p.phone_hash from public.profiles p
    where p.phone_hash = any(hashes) and p.id <> auth.uid()';

revoke execute on function public.match_contacts(text[]) from anon;
grant execute on function public.match_contacts(text[]) to authenticated;

-- 컬럼 자체의 조회 권한 회수 (덤프 차단)
-- ⚠️ 컬럼 단위 revoke는 테이블 전체 select 권한이 남아 있으면 무력화된다.
--    테이블 권한을 먼저 회수하고 허용 컬럼만 다시 부여해야 한다.
revoke select on public.profiles from anon, authenticated;

grant select (id, nickname, provider, avatar_emoji, friend_code, has_phone, created_at)
  on public.profiles to authenticated;

-- ── 3. 계정 삭제 (Google Play 필수 요건) ──────────────────
-- auth.users 삭제 시 profiles → 플레이리스트/친구/반응까지 cascade 삭제
create or replace function public.delete_my_account()
returns void
language sql
security definer
set search_path = public
as 'delete from auth.users where id = auth.uid()';

revoke execute on function public.delete_my_account() from anon;
grant execute on function public.delete_my_account() to authenticated;
