-- =====================================================================
-- 14_admin_invite_rpcs : 관리자가 보살 초대 코드를 생성하기 위한 RPC
--
--   - create_bosal_invite(bosal_id, expires_days, email) → 코드 문자열
--   - create_bosal_with_invite(name, phone_display, region_code, sub_region_code,
--                              expires_days, email)
--     → { bosal_id, invite_code } (빈 보살 레코드 + 초대 코드 한 번에 생성)
--
-- 보안: 두 함수 모두 is_admin() 체크. anon/authenticated는 실행만 가능하고
-- 내부 `security definer`가 실제 insert 수행.
-- =====================================================================

-- 랜덤 코드 생성 헬퍼: BOSAL-XXXX-XXXX (대소문자+숫자)
create or replace function public._generate_invite_code()
returns text
language sql
volatile
as $$
  select 'BOSAL-'
      || upper(substr(md5(random()::text || clock_timestamp()::text), 1, 4))
      || '-'
      || upper(substr(md5(random()::text || clock_timestamp()::text), 1, 4));
$$;

-- 1) 단순: 기존 보살에 초대 코드만 발급
create or replace function public.create_bosal_invite(
  p_bosal_id     uuid,
  p_expires_days int    default 30,
  p_email        text   default null
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text;
begin
  if not public.is_admin() then
    raise exception 'admin only' using errcode = '42501';
  end if;
  if not exists (select 1 from public.bosals where id = p_bosal_id) then
    raise exception 'bosal not found' using errcode = 'no_data_found';
  end if;

  -- 중복 회피: 매우 드물지만 5회까지 재시도
  for i in 1..5 loop
    v_code := public._generate_invite_code();
    begin
      insert into public.bosal_invites (code, bosal_id, email, expires_at)
      values (v_code, p_bosal_id, p_email, now() + make_interval(days => p_expires_days));
      return v_code;
    exception when unique_violation then
      -- try again
      null;
    end;
  end loop;
  raise exception 'failed to generate unique invite code';
end;
$$;

revoke all on function public.create_bosal_invite(uuid, int, text) from public;
grant execute on function public.create_bosal_invite(uuid, int, text) to authenticated;

-- 2) 원샷: 빈 보살 레코드 + 초대 코드를 한 번에 생성 (가장 자주 쓸 함수)
create or replace function public.create_bosal_with_invite(
  p_name             text,
  p_phone_display    text    default null,
  p_region_code      text    default null,
  p_sub_region_code  text    default null,
  p_expires_days     int     default 30,
  p_email            text    default null
)
returns table(bosal_id uuid, invite_code text)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_bosal_id    uuid;
  v_region_id   uuid;
  v_sub_region  uuid;
  v_code        text;
begin
  if not public.is_admin() then
    raise exception 'admin only' using errcode = '42501';
  end if;

  if p_region_code is not null then
    select id into v_region_id from public.regions where code = p_region_code;
  end if;
  if p_sub_region_code is not null then
    select id into v_sub_region from public.sub_regions where code = p_sub_region_code;
  end if;

  insert into public.bosals (name, phone_display, region_id, sub_region_id, is_published)
  values (p_name, p_phone_display, v_region_id, v_sub_region, false)
  returning id into v_bosal_id;

  for i in 1..5 loop
    v_code := public._generate_invite_code();
    begin
      insert into public.bosal_invites (code, bosal_id, email, expires_at)
      values (v_code, v_bosal_id, p_email, now() + make_interval(days => p_expires_days));
      bosal_id    := v_bosal_id;
      invite_code := v_code;
      return next;
      return;
    exception when unique_violation then
      null;
    end;
  end loop;
  raise exception 'failed to generate unique invite code';
end;
$$;

revoke all on function public.create_bosal_with_invite(text, text, text, text, int, text) from public;
grant execute on function public.create_bosal_with_invite(text, text, text, text, int, text) to authenticated;

-- 3) 편의 뷰: 관리자가 살아있는 초대 코드 목록을 볼 수 있도록
create or replace view public.v_active_bosal_invites as
select
  bi.code,
  bi.bosal_id,
  b.name as bosal_name,
  bi.email,
  bi.expires_at,
  bi.used_at,
  bi.used_by,
  case
    when bi.used_at is not null then 'used'
    when bi.expires_at < now()  then 'expired'
    else 'active'
  end as status
from public.bosal_invites bi
left join public.bosals b on b.id = bi.bosal_id
order by bi.created_at desc;

grant select on public.v_active_bosal_invites to authenticated;
