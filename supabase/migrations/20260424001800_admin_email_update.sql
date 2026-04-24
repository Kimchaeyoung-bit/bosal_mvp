-- =====================================================================
-- 18_admin_email_update : 부트스트랩 관리자 이메일을 전용 계정으로 변경
--
--   기존: bill@wadidu.com → 개인 이메일이라 유저 역할로도 쓰일 가능성
--   변경: gangnam-bosal-admin@wadidu.com → 관리자 전용 계정
--
--   bill@wadidu.com이 이미 admin으로 승격됐다면 role=user로 되돌린다.
-- =====================================================================

create or replace function public.tg_handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role    public.user_role := 'user';
  v_display text;
begin
  -- 관리자 전용 이메일
  if new.email = any (array[
    'gangnam-bosal-admin@wadidu.com'
  ]) then
    v_role := 'admin';
  end if;

  v_display := coalesce(
    new.raw_user_meta_data ->> 'display_name',
    split_part(new.email, '@', 1),
    '사용자'
  );

  insert into public.profiles (id, role, display_name)
  values (new.id, v_role, v_display);

  return new;
end;
$$;

-- 기존 관리자 이메일 (bill@wadidu.com)이 가입돼 있었다면 role 을 user 로 원복.
update public.profiles
   set role = 'user'
 where role = 'admin'
   and id in (
     select id from auth.users
      where email = any (array['bill@wadidu.com'])
   );

-- 새 관리자 이메일이 이미 가입돼 있었다면 즉시 admin 으로 승격.
update public.profiles
   set role = 'admin'
 where role <> 'admin'
   and id in (
     select id from auth.users
      where email = any (array['gangnam-bosal-admin@wadidu.com'])
   );
