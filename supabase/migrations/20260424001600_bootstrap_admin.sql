-- =====================================================================
-- 16_bootstrap_admin : 특정 이메일로 가입 시 자동 admin role 부여
--
--   부트스트랩: admin 계정이 아무도 없는 상태에서 is_admin() 체크가 걸려
--   RPC 호출이 막히는 chicken-and-egg 문제를 해결한다.
--   허용 이메일은 트리거 본문에 리스트업 (git-tracked으로 감사 가능).
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
  -- 부트스트랩 관리자 이메일 (필요 시 여기에 추가)
  if new.email = any (array[
    'bill@wadidu.com'
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

-- 이미 가입된 부트스트랩 이메일은 즉시 승격 (idempotent)
update public.profiles
   set role = 'admin'
 where id in (
   select id from auth.users
    where email = any (array['bill@wadidu.com'])
 )
   and role <> 'admin';
