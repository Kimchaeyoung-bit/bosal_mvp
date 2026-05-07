-- =====================================================================
-- 24_account_deletion : 회원 탈퇴 (anonymize)
--
--   Apple Guideline 5.1.1(v) 강제 요구. 사용자가 앱 내에서 직접 탈퇴 가능
--   해야 함.
--
--   정책 (D5 = anonymize):
--     - profiles.display_name → '탈퇴한 사용자'
--     - profiles.avatar_url → null
--     - profiles.deleted_at → now()
--     - favorites: hard delete (개인 취향 데이터)
--     - notifications: hard delete (수신자 식별 무의미)
--     - reservations / reviews: user_id 그대로 유지 (통계·평점 무결성).
--                              UI는 profiles 조인하여 '탈퇴한 사용자' 로 표시.
--     - auth.users: hard delete (cascade로 identities·sessions 정리)
--
--   확인 문구: 사용자가 '탈퇴합니다' 정확히 입력해야 실행 (실수 방지).
-- =====================================================================

create or replace function public.delete_my_account(p_confirm text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  if p_confirm <> '탈퇴합니다' then
    raise exception 'confirmation phrase mismatch' using errcode = 'check_violation';
  end if;

  -- 1) profiles anonymize (필요 시 cascade로 따라 가지만 명시적으로 표기)
  update public.profiles
     set display_name = '탈퇴한 사용자',
         avatar_url   = null,
         deleted_at   = now()
   where id = v_uid;

  -- 2) 개인 취향 데이터 hard delete
  delete from public.favorites where user_id = v_uid;
  delete from public.notifications where user_id = v_uid;

  -- 3) auth.users hard delete (auth.identities·refresh_tokens·sessions cascade)
  --    profiles는 FK on delete cascade 라 함께 삭제될 수 있으므로 anonymize는
  --    정보를 *기록*해두기 위함이지만, 통계·후기·예약은 user_id 보존이라
  --    Supabase auth.users PK 삭제 시 외래키가 막히지 않도록 profiles의
  --    FK 정책 확인 필요. 현재 profiles.id → auth.users.id ON DELETE CASCADE
  --    이므로 profiles row도 함께 삭제되며, reservations / reviews는
  --    user_id → profiles.id ON DELETE CASCADE 라면 사라짐.
  --    → 통계 무결성 보장 위해, 위 1) 단계에서 profiles만 남기고 auth.users
  --      삭제 시 cascade 발생을 차단해야 한다. 임시 해결: auth.users 삭제 대신
  --      비활성화(banned_until 설정)로 대체.
  update auth.users
     set banned_until = 'infinity'::timestamptz,
         email = concat('deleted+', v_uid::text, '@bosal.invalid'),
         encrypted_password = ''
   where id = v_uid;
end;
$$;

revoke all on function public.delete_my_account(text) from public;
grant execute on function public.delete_my_account(text) to authenticated;

-- 향후 검토:
--   * GDPR/PIPA 정의상 진정한 삭제가 필요하면 별도 admin 작업으로 hard delete.
--   * banned_until + email anonymize 조합은 재가입 시 이메일 충돌 방지.
