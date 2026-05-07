-- =====================================================================
-- 26_broadcast_notification : admin 공지 일괄 발송
--
--   외부 어드민 web (apps/admin_web) 의 /notifications/new 에서 호출.
--   대상:
--     - p_target_role IS NULL AND p_target_user_ids IS NULL → 전체 활성 사용자
--     - p_target_role 지정 → 해당 role 만 (user/bosal/admin)
--     - p_target_user_ids 지정 → 특정 user_id 배열
--   반환: 실제 insert된 알림 수
--
--   admin 권한 검증. profiles.deleted_at IS NOT NULL 사용자는 제외.
-- =====================================================================

create or replace function public.broadcast_notification(
  p_title           text,
  p_body            text,
  p_target_role     text   default null,
  p_target_user_ids uuid[] default null,
  p_data            jsonb  default '{}'::jsonb,
  p_type            text   default 'system'
)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count int;
begin
  if not public.is_admin() then
    raise exception 'admin only' using errcode = '42501';
  end if;
  if p_title is null or length(trim(p_title)) = 0 then
    raise exception 'title is required' using errcode = 'check_violation';
  end if;
  if p_body is null or length(trim(p_body)) = 0 then
    raise exception 'body is required' using errcode = 'check_violation';
  end if;
  if p_type not in ('booking', 'review', 'system', 'invite') then
    raise exception 'invalid type' using errcode = 'check_violation';
  end if;

  with targets as (
    select id
      from public.profiles
     where deleted_at is null
       and (p_target_role is null or role::text = p_target_role)
       and (p_target_user_ids is null or id = any(p_target_user_ids))
  ),
  ins as (
    insert into public.notifications (user_id, type, title, body, data)
    select t.id, p_type, p_title, p_body, coalesce(p_data, '{}'::jsonb)
      from targets t
    returning 1
  )
  select count(*)::int into v_count from ins;

  return v_count;
end;
$$;

revoke all on function public.broadcast_notification(text, text, text, uuid[], jsonb, text) from public;
grant execute on function public.broadcast_notification(text, text, text, uuid[], jsonb, text) to authenticated;
