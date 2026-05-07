# 외부 어드민 웹 ↔ Supabase 통합 가이드

회사의 별도 Next.js 어드민 프로젝트(미공개 URL)에서 본 Supabase 인스턴스에 접속해 운영 기능을 구현할 때 참고. 모바일 앱·관리자 웹·백엔드는 동일 Supabase 인스턴스를 공유하며, 권한은 `profiles.role` (user · bosal · admin) 로 분리.

관련 문서: [모노레포 README](../README.md) · [모바일 README](../apps/mobile/README.md) · [PRD](PRD.md).

---

## 1. 인증

1. Supabase 어드민 콘솔에서 admin 계정을 생성하거나, 부트스트랩 마이그레이션([20260424001600_bootstrap_admin.sql](../backend/supabase/migrations/20260424001600_bootstrap_admin.sql), [20260424001800_admin_email_update.sql](../backend/supabase/migrations/20260424001800_admin_email_update.sql))으로 사전 등록된 이메일을 사용.
2. Next.js 어드민에서 `@supabase/supabase-js` 사용. 로그인은 `supabase.auth.signInWithPassword`.
3. 로그인 후 `profiles.role === 'admin'` 검증 후 진입 허용:

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

4. 일반 사용자·보살 사장 계정으로 로그인하면 RLS가 admin 전용 RPC·뷰 접근을 차단.

---

## 2. 사용 가능한 RPC

| RPC | 파라미터 | 반환 | 비고 |
|---|---|---|---|
| `create_bosal_invite(p_bosal_id uuid, p_expires_days int default 30, p_email text default null)` | 기존 보살에게 발급 | `text` (code) | [20260424001400](../backend/supabase/migrations/20260424001400_admin_invite_rpcs.sql) |
| `create_bosal_with_invite(p_name text, p_phone_display text, p_region_code citext, p_sub_region_code citext, p_expires_days int default 30, p_email text default null)` | 빈 보살 + 코드 동시 생성 | `record (bosal_id uuid, invite_code text)` | 신규 보살 온보딩 진입점 |
| `claim_bosal_invite(p_code text)` | 사용자가 코드 입력 | `uuid` (bosal_id) | role=bosal 승격, profiles.bosal_id 연결 |
| `update_bosal_owner_fields(p_bosal_id uuid, …20개 nullable 필드)` | 화이트리스트 수정 | `bosals` row | 보살 본인 또는 admin |
| `replace_bosal_features(p_bosal_id uuid, p_labels text[])` | 특징 일괄 교체 | `setof bosal_features` | |
| `replace_bosal_categories(p_bosal_id uuid, p_category_codes citext[])` | M:N 일괄 교체 | `setof bosal_categories` | |
| `replace_operating_hours(p_bosal_id uuid, p_entries jsonb)` | 요일별 운영시간 | `setof operating_hours` | jsonb 배열, weekday 0~6 |
| `publish_bosal_profile(p_bosal_id uuid, p_is_published boolean)` | 공개 토글 | `bosals` row | |
| `confirm_reservation(p_reservation_id uuid, p_consult_at timestamptz)` | pending → confirmed | `reservations` row | |
| `cancel_reservation(p_reservation_id uuid, p_reason text default null)` | pending/confirmed → cancelled | `reservations` row | 사용자 자기예약·보살오너·admin |
| `complete_reservation(p_reservation_id uuid)` | confirmed → completed | `reservations` row | |
| `reject_reservation(p_reservation_id uuid, p_reason text default null)` | pending → cancelled (rejected) | `reservations` row | |
| `admin_list_bosal_analytics()` | — | `setof admin_bosal_analytics_row` | 보살별 KPI(아래) |
| `mark_notification_read(p_id uuid)` | 본인 알림 1건 read | `notifications` row | |
| `mark_all_notifications_read()` | 본인 미읽음 일괄 | `int` (갱신 행 수) | |

### `admin_list_bosal_analytics()` 반환 컬럼

`bosal_id, name, is_published, rating_avg, review_count, consult_request_count`
`call_24h, call_7d, call_30d, call_total`
`resv_24h, resv_7d, resv_30d, resv_total` (예약 버튼 탭 카운터)

자세한 정의: [`20260424002100_admin_analytics.sql`](../backend/supabase/migrations/20260424002100_admin_analytics.sql).

---

## 3. 직접 SELECT 가능한 뷰·테이블 (admin 전용 RLS 우회)

`profiles.role = 'admin'` 사용자는 RLS 정책에 의해 다음을 select 가능:

- `bosals` (모든 행, 미공개·삭제 포함)
- `profiles` (모든 행)
- `reservations`, `reviews`, `favorites`, `banner_ads`, `bosal_ai_personas`
- `bosal_invites` (admin 전용 select)
- `v_active_bosal_invites` (활성 초대 코드 view, view 자체에 admin 가드)
- `v_bosal_call_stats`, `v_bosal_reservation_button_stats` (집계 뷰; 보통 RPC 통해 호출 권장)

쓰기는 일부만 직접 가능(`banner_ads` admin only). 보살·예약·후기는 SECURITY DEFINER RPC 통해 변경 권장.

---

## 4. 알림 발송

알림은 트리거(`tg_reservations_notify`, `tg_reviews_notify`)가 자동 생성:

- 새 예약(insert) → 보살 사장에게 "새 예약 요청"
- 예약 status 전환 → 사용자에게 "예약 확정 / 취소 / 후기 작성 요청"
- 후기 insert → 보살에게 "새 후기 도착"

어드민이 수동으로 시스템 공지를 보내려면 admin RLS로 직접 insert:

```ts
await supabase.from('notifications').insert({
  user_id: '<target_uid>',
  type: 'system',
  title: '공지',
  body: '안내 메시지',
  data: { /* deep link payload */ },
});
```

> 전체 사용자 일괄 발송용 `broadcast_notification(target_role?, title, body)` RPC는 **현재 미구현**. 필요 시 신설 권장.

---

## 5. Storage

- `bosal-images` 버킷 — 보살 프로필/포트폴리오 이미지. public read, 소유자 write per `bosal_id` prefix.
- `banner-ads` 버킷 — admin only write.

배너 업로드 예:

```ts
await supabase.storage
  .from('banner-ads')
  .upload(`campaigns/2026-05/${file.name}`, file);
```

---

## 6. Realtime

다음 테이블이 `supabase_realtime` publication에 등록:

- `reservations` — 보살 사장 대시보드 실시간 갱신
- `notifications` — 사용자 알림 화면 실시간 갱신

```ts
supabase
  .channel('reservations')
  .on(
    'postgres_changes',
    { event: '*', schema: 'public', table: 'reservations' },
    (payload) => { /* ... */ }
  )
  .subscribe();
```

`supabase.from('reservations').stream(...)` 도 가능.

---

## 7. 환경 변수 (Next.js 어드민 측)

```
NEXT_PUBLIC_SUPABASE_URL=https://<project-ref>.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<anon_public_key>
# 서버사이드에서만:
SUPABASE_SERVICE_ROLE_KEY=<service_role_key>
```

- anon key는 클라이언트 노출 가정. RLS·RPC 가드로 보호.
- service_role key는 어드민 web의 서버사이드 API 라우트(예: `/api/...`)에서만 사용. 클라이언트 노출 금지.

---

## 8. 권한 매트릭스

| 작업 | 일반 사용자 | 보살 사장 | 관리자 |
|---|---|---|---|
| 자기 예약 조회 / 생성 / pending 취소 | ✓ | — | ✓ |
| 받은 예약 조회·확정·완료·거절 | — | 자기 보살만 | 모두 |
| 자기 프로필(profiles) 편집 | ✓ (display_name 등) | (보살 전용 RPC로) | ✓ |
| 다른 사용자 프로필 조회 | — | — | ✓ |
| 보살 초대 코드 발급 / 조회 | — | — | ✓ |
| 보살 분석 RPC (`admin_list_bosal_analytics`) | — | — | ✓ |
| 알림 자기 것 읽음 처리 / 삭제 | ✓ | ✓ | ✓ |
| 알림 직접 insert (시스템 공지) | — | — | ✓ |
| 후기 작성 | ✓ (completed 예약 보유 시) | ✓ (자기 받은 보살에는 작성 X) | ✓ |
| `bosals.is_published` 토글 | — | 자기 보살만 (publish_bosal_profile RPC) | 모두 |

---

## 9. 데모 데이터

마이그레이션 [`20260424002200_seed_inmuk_chaeyoung_bosals.sql`](../backend/supabase/migrations/20260424002200_seed_inmuk_chaeyoung_bosals.sql) 적용 시 자동 시드:

| 보살 | 이메일 | 비번 | 권역 | 스타일 | 광고 의향 |
|---|---|---|---|---|---|
| 인묵보살 | `inmuk@bosal.test` | `bosal1234` | 논현 | 직설(cool) | interested |
| 채영보살 | `chaeyoung@bosal.test` | `bosal1234` | 강남역 | 공감(empathetic) | none |

운영시간·카테고리·특징·가격은 시드 SQL 참고.

---

## 10. 참고 마이그레이션

- `is_admin()` 헬퍼 / profiles 트리거: [20260424000200](../backend/supabase/migrations/20260424000200_profiles.sql)
- RLS 정책 마스터: [20260424000800](../backend/supabase/migrations/20260424000800_rls_policies.sql)
- 예약 상태 머신 RPC: [20260424000900](../backend/supabase/migrations/20260424000900_rpcs.sql)
- 보살 초대 RPC: [20260424001400](../backend/supabase/migrations/20260424001400_admin_invite_rpcs.sql)
- 보살 프로필 RPC: [20260424001500](../backend/supabase/migrations/20260424001500_bosal_profile_rpcs.sql)
- 알림 시스템: [20260424002000](../backend/supabase/migrations/20260424002000_notifications.sql)
- 어드민 분석 RPC: [20260424002100](../backend/supabase/migrations/20260424002100_admin_analytics.sql)
- 룩업 시드 (categories · regions · sub_regions): [20260424001200](../backend/supabase/migrations/20260424001200_seed_lookups.sql), [20260424001900](../backend/supabase/migrations/20260424001900_extend_lookups.sql)
