-- =====================================================================
-- 27_view_events_and_analytics : 보살 상세 조회수 트래킹 + analytics RPC 확장
--
--   목적:
--     - 어드민이 보살별 (전화·예약·조회수·좋아요) 모두 수치 확인 가능하게
--   추가:
--     1. bosal_view_events 테이블 (call_events와 동일 패턴)
--     2. v_bosal_view_stats 뷰 (24h/7d/30d/total)
--     3. admin_list_bosal_analytics RPC 재정의 — view·favorite 컬럼 추가
-- =====================================================================

-- ---------- 1) bosal_view_events ----------
create table if not exists public.bosal_view_events (
  id          uuid         primary key default gen_random_uuid(),
  bosal_id    uuid         not null references public.bosals(id) on delete cascade,
  user_id     uuid         references auth.users(id) on delete set null,
  session_id  text,
  created_at  timestamptz  not null default now()
);
create index if not exists bosal_view_events_bosal_idx
  on public.bosal_view_events (bosal_id, created_at desc);
create index if not exists bosal_view_events_user_idx
  on public.bosal_view_events (user_id, created_at desc)
  where user_id is not null;

alter table public.bosal_view_events enable row level security;

-- 인증된 사용자가 자기 view 만 insert. user_id 누락(익명) 도 허용 — anon role 사용 시.
create policy bosal_view_events_insert
  on public.bosal_view_events for insert
  with check (
    user_id is null or user_id = auth.uid()
  );

-- 조회는 admin 만 (개인 정보 보호)
create policy bosal_view_events_admin_select
  on public.bosal_view_events for select
  using (public.is_admin());

-- ---------- rate-limit 트리거: 같은 user/세션이 같은 보살 5초 내 중복 조회 차단 ----------
create or replace function public.tg_bosal_view_events_rate_limit()
returns trigger
language plpgsql as $$
declare
  v_recent boolean;
begin
  if new.user_id is not null then
    select exists(
      select 1 from public.bosal_view_events
       where bosal_id = new.bosal_id
         and user_id = new.user_id
         and created_at > now() - interval '5 seconds'
    ) into v_recent;
  elsif new.session_id is not null then
    select exists(
      select 1 from public.bosal_view_events
       where bosal_id = new.bosal_id
         and session_id = new.session_id
         and created_at > now() - interval '5 seconds'
    ) into v_recent;
  else
    v_recent := false;
  end if;
  if v_recent then
    return null;  -- silent skip
  end if;
  return new;
end;
$$;

drop trigger if exists bosal_view_events_rate_limit on public.bosal_view_events;
create trigger bosal_view_events_rate_limit
  before insert on public.bosal_view_events
  for each row execute function public.tg_bosal_view_events_rate_limit();


-- ---------- 2) v_bosal_view_stats ----------
create or replace view public.v_bosal_view_stats as
select
  b.id as bosal_id,
  count(*) filter (where ev.created_at > now() - interval '24 hours')::int as view_24h,
  count(*) filter (where ev.created_at > now() - interval '7 days')::int  as view_7d,
  count(*) filter (where ev.created_at > now() - interval '30 days')::int as view_30d,
  count(ev.id)::int as view_total
  from public.bosals b
  left join public.bosal_view_events ev on ev.bosal_id = b.id
 where b.deleted_at is null
 group by b.id;


-- ---------- 3) admin_list_bosal_analytics 재정의 ----------
-- 기존 함수 drop 후 새 시그니처 (favorite_count + view_* 4개 추가).
drop function if exists public.admin_list_bosal_analytics();

create or replace function public.admin_list_bosal_analytics()
returns table (
  bosal_id              uuid,
  name                  text,
  is_published          boolean,
  rating_avg            numeric,
  review_count          int,
  consult_request_count int,
  -- 전화 탭
  call_24h              int,
  call_7d               int,
  call_30d              int,
  call_total            int,
  -- 예약 버튼 탭
  resv_24h              int,
  resv_7d               int,
  resv_30d              int,
  resv_total            int,
  -- 보살 상세 조회수
  view_24h              int,
  view_7d               int,
  view_30d              int,
  view_total            int,
  -- 좋아요(찜)
  favorite_count        int
)
language sql
security definer
set search_path = public
as $$
  select
    b.id,
    b.name,
    b.is_published,
    b.rating_avg,
    b.review_count,
    b.consult_request_count,
    coalesce(cs.call_24h, 0),
    coalesce(cs.call_7d, 0),
    coalesce(cs.call_30d, 0),
    coalesce(cs.call_total, 0),
    coalesce(rs.resv_24h, 0),
    coalesce(rs.resv_7d, 0),
    coalesce(rs.resv_30d, 0),
    coalesce(rs.resv_total, 0),
    coalesce(vs.view_24h, 0),
    coalesce(vs.view_7d, 0),
    coalesce(vs.view_30d, 0),
    coalesce(vs.view_total, 0),
    coalesce(fav.favorite_count, 0)::int
    from public.bosals b
    left join public.v_bosal_call_stats               cs  on cs.bosal_id  = b.id
    left join public.v_bosal_reservation_button_stats rs  on rs.bosal_id  = b.id
    left join public.v_bosal_view_stats               vs  on vs.bosal_id  = b.id
    left join lateral (
      select count(*)::int as favorite_count
        from public.favorites f
       where f.bosal_id = b.id
    ) fav on true
   where b.deleted_at is null
     and public.is_admin()
   order by b.created_at desc;
$$;

revoke all on function public.admin_list_bosal_analytics() from public;
grant execute on function public.admin_list_bosal_analytics() to authenticated;
