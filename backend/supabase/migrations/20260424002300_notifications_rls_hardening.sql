-- =====================================================================
-- 23_notifications_rls_hardening : 알림 update 경로 RPC-only로 강화
--
--   기존 [20260424002000_notifications.sql] 의 `notifications_self_update`
--   정책은 본인 행에 대해 update 자체를 허용하고, 컬럼 변경은 트리거가 검증.
--   하지만 `with check`가 USING 과 동일해 admin 우회·트리거 회피 시도 가능.
--
--   여기서는 일반 사용자의 직접 update를 차단하고, 읽음 처리는
--   `mark_notification_read` / `mark_all_notifications_read` (SECURITY
--   DEFINER) RPC로만 가능하도록 강제. admin은 모든 컬럼 update 가능 (공지
--   본문 수정 등 운영 케이스).
-- =====================================================================

-- 1) 기존 정책 제거
drop policy if exists notifications_self_update on public.notifications;

-- 2) admin-only update 정책으로 교체
create policy notifications_admin_update
  on public.notifications for update
  using (public.is_admin())
  with check (public.is_admin());

-- 3) immutable_fields 트리거는 admin 우회 분기를 그대로 유지
--    (admin이 RLS를 통과한 update에서도 read_at 자동 보정 등 일관성 유지)
--    별도 변경 없음.

-- 4) 사용자는 RPC 통해서만 read 토글 가능. mark_notification_read는
--    이미 SECURITY DEFINER + auth.uid() 일치 체크 + update SET 명시.

-- 검증:
--   psql 또는 Supabase SQL editor에서:
--     -- 사용자 세션
--     update public.notifications set is_read = true where id = '<own_id>';
--     -- expected: 0 rows updated (RLS 정책 미통과)
--
--     -- mark_notification_read 호출
--     select public.mark_notification_read('<own_id>'::uuid);
--     -- expected: 정상 row 반환
