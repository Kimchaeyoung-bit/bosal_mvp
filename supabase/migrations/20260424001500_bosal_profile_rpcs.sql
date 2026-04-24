-- =====================================================================
-- 15_bosal_profile_rpcs : 보살 본인이 프로필을 편집하는 RPC
--
--   - update_bosal_owner_fields : 안전한 화이트리스트 필드만 갱신
--   - replace_bosal_features    : 특징 리스트 일괄 교체
--   - replace_bosal_categories  : 카테고리 M:N 일괄 교체
--   - replace_operating_hours   : 요일별 운영 시간 일괄 교체
--   - publish_bosal_profile     : 온보딩 완료 시 is_published=true 토글
-- =====================================================================

create or replace function public.update_bosal_owner_fields(
  p_bosal_id         uuid,
  p_name             text    default null,
  p_one_liner        text    default null,
  p_description      text    default null,
  p_experience_years int     default null,
  p_consult_style    text    default null,   -- consult_styles.code
  p_phone_display    text    default null,
  p_phone_e164       text    default null,
  p_original_price   int     default null,
  p_discounted_price int     default null,
  p_first_visit_price int    default null,
  p_max_points       int     default null,
  p_sido             text    default null,
  p_sigungu          text    default null,
  p_eupmyeondong     text    default null,
  p_road_address     text    default null,
  p_jibun_address    text    default null,
  p_postal_code      text    default null,
  p_region_code      text    default null,
  p_sub_region_code  text    default null,
  p_latitude         numeric default null,
  p_longitude        numeric default null
)
returns public.bosals
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row          public.bosals%rowtype;
  v_style_id     uuid;
  v_region_id    uuid;
  v_sub_region   uuid;
  v_location     geography(Point,4326);
begin
  if not (public.is_bosal_owner(p_bosal_id) or public.is_admin()) then
    raise exception 'not authorized' using errcode = '42501';
  end if;

  if p_consult_style is not null then
    select id into v_style_id from public.consult_styles where code = p_consult_style;
  end if;
  if p_region_code is not null then
    select id into v_region_id from public.regions where code = p_region_code;
  end if;
  if p_sub_region_code is not null then
    select id into v_sub_region from public.sub_regions where code = p_sub_region_code;
  end if;
  if p_latitude is not null and p_longitude is not null then
    v_location := ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography;
  end if;

  update public.bosals set
    name               = coalesce(p_name, name),
    one_liner          = coalesce(p_one_liner, one_liner),
    description        = coalesce(p_description, description),
    experience_years   = coalesce(p_experience_years, experience_years),
    consult_style_id   = coalesce(v_style_id, consult_style_id),
    phone_display      = coalesce(p_phone_display, phone_display),
    phone_e164         = coalesce(p_phone_e164, phone_e164),
    original_price     = coalesce(p_original_price, original_price),
    discounted_price   = coalesce(p_discounted_price, discounted_price),
    first_visit_price  = coalesce(p_first_visit_price, first_visit_price),
    max_points         = coalesce(p_max_points, max_points),
    sido               = coalesce(p_sido, sido),
    sigungu            = coalesce(p_sigungu, sigungu),
    eupmyeondong       = coalesce(p_eupmyeondong, eupmyeondong),
    road_address       = coalesce(p_road_address, road_address),
    jibun_address      = coalesce(p_jibun_address, jibun_address),
    postal_code        = coalesce(p_postal_code, postal_code),
    region_id          = coalesce(v_region_id, region_id),
    sub_region_id      = coalesce(v_sub_region, sub_region_id),
    location           = coalesce(v_location, location)
  where id = p_bosal_id
  returning * into v_row;

  return v_row;
end;
$$;

revoke all on function public.update_bosal_owner_fields(
  uuid, text, text, text, int, text, text, text, int, int, int, int,
  text, text, text, text, text, text, text, text, numeric, numeric
) from public;
grant execute on function public.update_bosal_owner_fields(
  uuid, text, text, text, int, text, text, text, int, int, int, int,
  text, text, text, text, text, text, text, text, numeric, numeric
) to authenticated;

-- =====================================================================
-- replace_bosal_features(bosal_id, labels[])  — 특징 전체 교체
-- =====================================================================
create or replace function public.replace_bosal_features(
  p_bosal_id uuid,
  p_labels   text[]
)
returns setof public.bosal_features
language plpgsql
security definer
set search_path = public
as $$
declare
  v_i int;
begin
  if not (public.is_bosal_owner(p_bosal_id) or public.is_admin()) then
    raise exception 'not authorized' using errcode = '42501';
  end if;

  delete from public.bosal_features where bosal_id = p_bosal_id;

  if p_labels is not null then
    for v_i in 1 .. array_length(p_labels, 1) loop
      if p_labels[v_i] is not null and length(trim(p_labels[v_i])) > 0 then
        insert into public.bosal_features (bosal_id, label, sort_order)
        values (p_bosal_id, p_labels[v_i], v_i - 1);
      end if;
    end loop;
  end if;

  return query select * from public.bosal_features where bosal_id = p_bosal_id order by sort_order;
end;
$$;

revoke all on function public.replace_bosal_features(uuid, text[]) from public;
grant execute on function public.replace_bosal_features(uuid, text[]) to authenticated;

-- =====================================================================
-- replace_bosal_categories(bosal_id, category_codes[])
-- =====================================================================
create or replace function public.replace_bosal_categories(
  p_bosal_id       uuid,
  p_category_codes text[]
)
returns setof public.bosal_categories
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text;
  v_cid  uuid;
begin
  if not (public.is_bosal_owner(p_bosal_id) or public.is_admin()) then
    raise exception 'not authorized' using errcode = '42501';
  end if;

  delete from public.bosal_categories where bosal_id = p_bosal_id;

  if p_category_codes is not null then
    foreach v_code in array p_category_codes loop
      select id into v_cid from public.categories where code = v_code;
      if v_cid is not null then
        insert into public.bosal_categories (bosal_id, category_id)
        values (p_bosal_id, v_cid)
        on conflict do nothing;
      end if;
    end loop;
  end if;

  return query select * from public.bosal_categories where bosal_id = p_bosal_id;
end;
$$;

revoke all on function public.replace_bosal_categories(uuid, text[]) from public;
grant execute on function public.replace_bosal_categories(uuid, text[]) to authenticated;

-- =====================================================================
-- replace_operating_hours(bosal_id, jsonb[])
--   각 요소: { weekday, opens_at, closes_at, break_start?, break_end?, note? }
--   weekday 누락된 요일은 휴무로 간주하여 null/null 로 채운다.
-- =====================================================================
create or replace function public.replace_operating_hours(
  p_bosal_id uuid,
  p_entries  jsonb
)
returns setof public.operating_hours
language plpgsql
security definer
set search_path = public
as $$
declare
  v_entry jsonb;
  v_wd    smallint;
begin
  if not (public.is_bosal_owner(p_bosal_id) or public.is_admin()) then
    raise exception 'not authorized' using errcode = '42501';
  end if;

  -- 모든 요일에 대해 기본(null/null) 삽입 또는 기존 삭제
  delete from public.operating_hours where bosal_id = p_bosal_id;

  if p_entries is not null then
    for v_entry in select * from jsonb_array_elements(p_entries) loop
      v_wd := (v_entry->>'weekday')::smallint;
      insert into public.operating_hours (
        bosal_id, weekday, opens_at, closes_at, break_start, break_end, note
      ) values (
        p_bosal_id,
        v_wd,
        (v_entry->>'opens_at')::time,
        (v_entry->>'closes_at')::time,
        nullif(v_entry->>'break_start','')::time,
        nullif(v_entry->>'break_end','')::time,
        v_entry->>'note'
      )
      on conflict (bosal_id, weekday) do update
         set opens_at = excluded.opens_at,
             closes_at = excluded.closes_at,
             break_start = excluded.break_start,
             break_end = excluded.break_end,
             note = excluded.note;
    end loop;
  end if;

  return query
    select * from public.operating_hours
     where bosal_id = p_bosal_id
     order by weekday;
end;
$$;

revoke all on function public.replace_operating_hours(uuid, jsonb) from public;
grant execute on function public.replace_operating_hours(uuid, jsonb) to authenticated;

-- =====================================================================
-- publish_bosal_profile(bosal_id, is_published)
--   온보딩 완료 시 is_published=true로 전환. 소유자가 직접 토글 가능.
-- =====================================================================
create or replace function public.publish_bosal_profile(
  p_bosal_id     uuid,
  p_is_published boolean
)
returns public.bosals
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.bosals%rowtype;
begin
  if not (public.is_bosal_owner(p_bosal_id) or public.is_admin()) then
    raise exception 'not authorized' using errcode = '42501';
  end if;

  update public.bosals
     set is_published = p_is_published
   where id = p_bosal_id
  returning * into v_row;

  return v_row;
end;
$$;

revoke all on function public.publish_bosal_profile(uuid, boolean) from public;
grant execute on function public.publish_bosal_profile(uuid, boolean) to authenticated;
