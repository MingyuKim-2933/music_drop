-- MUSE 초기 스키마
-- Supabase 대시보드 > SQL Editor 에 붙여넣어 실행하거나
-- `supabase db push` 로 적용한다.

-- ── 프로필 ──────────────────────────────────────────────
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nickname text not null,
  provider text not null default 'email', -- kakao | naver | email
  phone_hash text unique,                 -- 연락처 매칭용 (E.164 SHA-256)
  avatar_emoji text not null default '🎧',
  created_at timestamptz not null default now()
);

-- 회원가입 시 프로필 자동 생성 (metadata의 nickname 사용)
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, nickname, provider)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'nickname', 'MUSE 유저'),
    coalesce(new.raw_user_meta_data->>'provider', 'email')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ── 지금 듣는 중 (감상 상태) ─────────────────────────────
create table public.now_playing (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  title text not null,
  artist text not null,
  source text not null,           -- melon | genie | flo | youtubeMusic | spotify ...
  is_playing boolean not null default false,
  updated_at timestamptz not null default now()
);

-- ── 친구 관계 ───────────────────────────────────────────
create table public.friendships (
  user_id uuid not null references public.profiles(id) on delete cascade,
  friend_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, friend_id),
  check (user_id <> friend_id)
);

-- ── 플레이리스트 ────────────────────────────────────────
create table public.playlists (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  emoji text not null default '🎵',
  forked_from_title text,          -- "지우님의 새벽 감성" (원본 삭제돼도 표시용으로 보존)
  is_public boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.playlist_songs (
  playlist_id uuid not null references public.playlists(id) on delete cascade,
  track_id bigint not null,        -- iTunes trackId
  title text not null,
  artist text not null,
  artwork_url text,
  preview_url text,
  store_url text,
  position int not null default 0,
  primary key (playlist_id, track_id)
);

create table public.playlist_likes (
  playlist_id uuid not null references public.playlists(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (playlist_id, user_id)
);

create index idx_playlists_owner on public.playlists(owner_id);
create index idx_playlists_public on public.playlists(is_public, updated_at desc);

-- ── RLS (Row Level Security) ────────────────────────────
alter table public.profiles enable row level security;
alter table public.now_playing enable row level security;
alter table public.friendships enable row level security;
alter table public.playlists enable row level security;
alter table public.playlist_songs enable row level security;
alter table public.playlist_likes enable row level security;

-- 프로필: 로그인 유저는 모두 조회 가능(닉네임 표시용), 수정은 본인만
create policy "profiles_select" on public.profiles
  for select to authenticated using (true);
create policy "profiles_update" on public.profiles
  for update to authenticated using (auth.uid() = id);

-- 감상 상태: 조회는 로그인 유저 모두(친구 피드), 쓰기는 본인만
create policy "now_playing_select" on public.now_playing
  for select to authenticated using (true);
create policy "now_playing_upsert" on public.now_playing
  for insert to authenticated with check (auth.uid() = user_id);
create policy "now_playing_update" on public.now_playing
  for update to authenticated using (auth.uid() = user_id);

-- 친구: 내 관계만 조회/생성/삭제
create policy "friendships_select" on public.friendships
  for select to authenticated using (auth.uid() = user_id or auth.uid() = friend_id);
create policy "friendships_insert" on public.friendships
  for insert to authenticated with check (auth.uid() = user_id);
create policy "friendships_delete" on public.friendships
  for delete to authenticated using (auth.uid() = user_id);

-- 플레이리스트: 공개된 것 + 내 것 조회, 쓰기는 소유자만
create policy "playlists_select" on public.playlists
  for select to authenticated using (is_public or owner_id = auth.uid());
create policy "playlists_insert" on public.playlists
  for insert to authenticated with check (owner_id = auth.uid());
create policy "playlists_update" on public.playlists
  for update to authenticated using (owner_id = auth.uid());
create policy "playlists_delete" on public.playlists
  for delete to authenticated using (owner_id = auth.uid());

-- 곡: 부모 플레이리스트 정책을 따름
create policy "playlist_songs_select" on public.playlist_songs
  for select to authenticated using (
    exists (select 1 from public.playlists p
            where p.id = playlist_id and (p.is_public or p.owner_id = auth.uid()))
  );
create policy "playlist_songs_write" on public.playlist_songs
  for all to authenticated using (
    exists (select 1 from public.playlists p
            where p.id = playlist_id and p.owner_id = auth.uid())
  ) with check (
    exists (select 1 from public.playlists p
            where p.id = playlist_id and p.owner_id = auth.uid())
  );

-- 좋아요: 모두 조회, 내 것만 추가/삭제
create policy "playlist_likes_select" on public.playlist_likes
  for select to authenticated using (true);
create policy "playlist_likes_insert" on public.playlist_likes
  for insert to authenticated with check (user_id = auth.uid());
create policy "playlist_likes_delete" on public.playlist_likes
  for delete to authenticated using (user_id = auth.uid());
