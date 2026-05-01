# 외부 어드민 웹 ↔ Supabase 통합 가이드

회사의 Next.js 어드민 프로젝트에서 본 Supabase 인스턴스에 접속해 운영 기능을 구현할 때 참고.

## 인증

1. Supabase 어드민 콘솔에서 **admin 계정 생성** 또는 기존 계정의 `profiles.role = 'admin'` 으로 갱신.
2. Next.js 어드민에서 `@supabase/supabase-js` 사용. 로그인은 `supabase.auth.signInWithPassword`.
3. 로그인 후 `profiles.role` 검증:
   ```ts
   const { data: profile } = await supabase
     .from('profiles')
     .select('role')
     .eq('id', user.id)
     .single();
   if (profile?.role !== 'admin') {
     await supabase.auth.signOut();
     throw new Error('관리자 권한이 없습니다');
   }
   ```

## 사용 가능한 RPC

| RPC | 파라미터 | 반환 | 설명 |
|---|---|---|---|
| `create_bosal_invite(p_bosal_id, p_expires_days, p_email)` | bosal_id, 30, email? | text (code) | 기존 보살에 초대 코드 발급 |
| `create_bosal_with_invite(p_name, p_phone_display, p_region_code, p_sub_region_code, p_expires_days, p_email)` | 보살 정보 | `{bosal_id, invite_code}` | 빈 보살 + 코드 동시 생성 |
| `claim_bosal_invite(p_code)` | code | uuid (bosal_id) | 사용자가 코드 입력 후 role=bosal 승격 |
| `admin_list_bosal_analytics()` | — | row[] | 보살별 24h/7d/30d 통계 (call_total, call_24h, …, resv_btn_total, resv_btn_24h, …, rating_avg, review_count, consult_request_count, is_published) |
| `update_bosal_owner_fields(p_bosal_id, …20필드)` | bosal_id + partial | bosals row | 보살 프로필 화이트리스트 수정. admin도 호출 가능 |
| `replace_bosal_features / replace_bosal_categories / replace_operating_hours` | bosal_id, 배열 | setof | 일괄 교체 |
| `publish_bosal_profile(p_bosal_id, p_is_published)` | bosal_id, bool | bosals row | 공개 토글 |
| `confirm_reservation / cancel_reservation / complete_reservation / reject_reservation` | reservation_id, … | reservations row | 예약 상태 머신 |
| `mark_notification_read(p_id)` / `mark_all_notifications_read()` | — | row / int | 알림 읽음 처리 |

## 직접 SELECT 가능한 뷰·테이블

`profiles.role = 'admin'` 사용자는 RLS 정책에 의해 다음을 select 가능:

- `bosals` (모든 행, 미공개 포함)
- `profiles` (모든 행)
- `reservations`, `reviews`, `favorites`, `banner_ads`, `bosal_ai_personas`
- `bosal_invites` (RLS는 admin만 select)
- `v_active_bosal_invites` (활성 초대 코드 view, view 자체에 admin 가드)
- `v_bosal_call_stats`, `v_bosal_reservation_button_stats` (집계 뷰; 일반적으로 RPC 통해 호출)

## 알림 발송

알림은 트리거(`tg_reservations_notify`, `tg_reviews_notify`)가 자동 생성. 어드민이 시스템 공지를 직접 발송하려면 admin RLS로 직접 insert:

```ts
await supabase.from('notifications').insert({
  user_id: '<target_uid>',
  type: 'system',
  title: '공지',
  body: '안내 메시지',
  data: {},
});
```

브로드캐스트(전체 사용자)는 별도 RPC 신설 권장 (현재 미구현).

## Storage

- `bosal-images` 버킷 — 보살 프로필/포트폴리오 이미지 (public read, owner write per `bosal_id` prefix)
- `banner-ads` 버킷 — admin only write

배너 이미지 업로드:
```ts
await supabase.storage.from('banner-ads').upload(path, file);
```

## Realtime

- `reservations`, `notifications` 활성화. `supabase.from(...).stream(...)` 또는 `supabase.channel(...).on('postgres_changes', ...)`.

## 환경변수 (Next.js)

```
NEXT_PUBLIC_SUPABASE_URL=...
NEXT_PUBLIC_SUPABASE_ANON_KEY=...
```

Service role key는 어드민 web 자체 서버사이드 API 라우트에서만 사용. 클라이언트 노출 금지.

## 권한 매트릭스

| 작업 | 일반 사용자 | 보살 사장 | 관리자 |
|---|---|---|---|
| 자기 예약 조회/생성/취소 | ✓ | — | ✓ |
| 받은 예약 조회·확정·완료·거절 | — | 자기 보살만 | 모두 |
| 자기 프로필 편집 | ✓ | (보살 전용 RPC) | ✓ |
| 다른 사용자 프로필 조회 | — | — | ✓ |
| 보살 초대 코드 발급/조회 | — | — | ✓ |
| 보살 분석 RPC | — | — | ✓ |
| 알림 자기것 읽음 처리 | ✓ | ✓ | ✓ |
| 알림 작성 (직접 insert) | — | — | ✓ |

## 참고

- `is_admin()` 헬퍼: `backend/supabase/migrations/20260424000200_profiles.sql`
- 부트스트랩 admin: `backend/supabase/migrations/20260424001600_bootstrap_admin.sql`
- RLS 정책 전체: `backend/supabase/migrations/20260424000800_rls_policies.sql`
