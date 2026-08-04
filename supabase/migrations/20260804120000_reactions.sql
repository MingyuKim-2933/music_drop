-- 이모지 반응 테이블
-- Supabase 대시보드 > SQL Editor 에서 실행할 것.

create table public.reactions (
  id uuid primary key default gen_random_uuid(),
  from_user uuid not null references public.profiles(id) on delete cascade,
  to_user uuid not null references public.profiles(id) on delete cascade,
  emoji text not null default '🫶',
  track_title text,          -- 반응 시점에 상대가 듣고 있던 곡 (표시용)
  created_at timestamptz not null default now()
);

create index idx_reactions_to_user on public.reactions(to_user, created_at desc);

alter table public.reactions enable row level security;

-- 보내기: 보낸 사람 = 나
create policy "reactions_insert" on public.reactions
  for insert to authenticated with check (from_user = auth.uid());

-- 조회: 내가 보냈거나 받은 것만
create policy "reactions_select" on public.reactions
  for select to authenticated using (from_user = auth.uid() or to_user = auth.uid());

-- 삭제: 받은 사람이 정리 가능
create policy "reactions_delete" on public.reactions
  for delete to authenticated using (to_user = auth.uid());
