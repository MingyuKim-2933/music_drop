-- 플레이리스트 기능 업그레이드
-- Supabase 대시보드 > SQL Editor 에서 실행할 것.

-- 퍼가기 카운트용: 원본 플레이리스트 참조 (개수는 이 FK로 집계)
alter table public.playlists
  add column forked_from uuid references public.playlists(id) on delete set null;

-- 내 플레이리스트 수동 정렬 순서
alter table public.playlists
  add column sort_order int not null default 0;

create index idx_playlists_forked_from on public.playlists(forked_from);
