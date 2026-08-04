-- 친구 그룹 (피드 분리용)
-- Supabase 대시보드 > SQL Editor 에서 실행할 것.

create table public.friend_groups (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  emoji text not null default '👥',
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

create table public.friend_group_members (
  group_id uuid not null references public.friend_groups(id) on delete cascade,
  friend_id uuid not null references public.profiles(id) on delete cascade,
  primary key (group_id, friend_id)
);

create index idx_friend_groups_owner on public.friend_groups(owner_id, sort_order);

alter table public.friend_groups enable row level security;
alter table public.friend_group_members enable row level security;

-- 그룹: 소유자만 전권
create policy "friend_groups_all" on public.friend_groups
  for all to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

-- 그룹 멤버: 부모 그룹의 소유자만
create policy "friend_group_members_all" on public.friend_group_members
  for all to authenticated
  using (
    exists (select 1 from public.friend_groups g
            where g.id = group_id and g.owner_id = auth.uid())
  )
  with check (
    exists (select 1 from public.friend_groups g
            where g.id = group_id and g.owner_id = auth.uid())
  );
