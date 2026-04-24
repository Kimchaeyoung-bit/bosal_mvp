-- =====================================================================
-- 05_events_counters : raw tap events + denormalized counter triggers
--   call_events, reservation_button_events
-- =====================================================================

-- ---------------- call_events ----------------
create table public.call_events (
  id          bigint                   generated always as identity primary key,
  bosal_id    uuid                     not null references public.bosals(id) on delete cascade,
  user_id     uuid                              references public.profiles(id) on delete set null,
  session_id  text,
  client_ts   timestamptz,
  server_ts   timestamptz              not null default now(),
  user_agent  text
);
create index call_events_bosal_ts_idx on public.call_events (bosal_id, server_ts desc);
create index call_events_user_ts_idx  on public.call_events (user_id, server_ts desc)
  where user_id is not null;

-- Rate-limit: same (user_id, bosal_id) within 3 seconds rejected
create or replace function public.tg_call_events_ratelimit()
returns trigger
language plpgsql
as $$
begin
  if new.user_id is not null then
    if exists (
      select 1 from public.call_events
       where user_id = new.user_id
         and bosal_id = new.bosal_id
         and server_ts > now() - interval '3 seconds'
    ) then
      raise exception 'call_events rate limit: duplicate tap within 3s'
        using errcode = 'check_violation';
    end if;
  end if;
  return new;
end;
$$;
create trigger call_events_ratelimit
  before insert on public.call_events
  for each row execute function public.tg_call_events_ratelimit();

-- Aggregate: bump bosals.call_count
create or replace function public.tg_call_events_bump_counter()
returns trigger
language plpgsql
as $$
begin
  update public.bosals
     set call_count = call_count + 1
   where id = new.bosal_id;
  return new;
end;
$$;
create trigger call_events_bump
  after insert on public.call_events
  for each row execute function public.tg_call_events_bump_counter();

-- ---------------- reservation_button_events ----------------
create table public.reservation_button_events (
  id          bigint                   generated always as identity primary key,
  bosal_id    uuid                     not null references public.bosals(id) on delete cascade,
  user_id     uuid                              references public.profiles(id) on delete set null,
  session_id  text,
  client_ts   timestamptz,
  server_ts   timestamptz              not null default now(),
  user_agent  text
);
create index reservation_button_events_bosal_ts_idx
  on public.reservation_button_events (bosal_id, server_ts desc);
create index reservation_button_events_user_ts_idx
  on public.reservation_button_events (user_id, server_ts desc)
  where user_id is not null;

create or replace function public.tg_resv_btn_ratelimit()
returns trigger
language plpgsql
as $$
begin
  if new.user_id is not null then
    if exists (
      select 1 from public.reservation_button_events
       where user_id = new.user_id
         and bosal_id = new.bosal_id
         and server_ts > now() - interval '3 seconds'
    ) then
      raise exception 'reservation_button_events rate limit: duplicate tap within 3s'
        using errcode = 'check_violation';
    end if;
  end if;
  return new;
end;
$$;
create trigger reservation_button_events_ratelimit
  before insert on public.reservation_button_events
  for each row execute function public.tg_resv_btn_ratelimit();

create or replace function public.tg_resv_btn_bump_counter()
returns trigger
language plpgsql
as $$
begin
  update public.bosals
     set reservation_button_count = reservation_button_count + 1
   where id = new.bosal_id;
  return new;
end;
$$;
create trigger reservation_button_events_bump
  after insert on public.reservation_button_events
  for each row execute function public.tg_resv_btn_bump_counter();

-- ---------------- aggregate view for bosal owners (no raw access) ----------------
create or replace view public.v_bosal_call_stats as
select
  bosal_id,
  count(*)::int                                          as total_calls,
  count(*) filter (where server_ts > now() - interval '24 hours')::int  as calls_24h,
  count(*) filter (where server_ts > now() - interval '7 days')::int    as calls_7d,
  count(*) filter (where server_ts > now() - interval '30 days')::int   as calls_30d
from public.call_events
group by bosal_id;

create or replace view public.v_bosal_reservation_button_stats as
select
  bosal_id,
  count(*)::int                                          as total_taps,
  count(*) filter (where server_ts > now() - interval '24 hours')::int  as taps_24h,
  count(*) filter (where server_ts > now() - interval '7 days')::int    as taps_7d,
  count(*) filter (where server_ts > now() - interval '30 days')::int   as taps_30d
from public.reservation_button_events
group by bosal_id;
