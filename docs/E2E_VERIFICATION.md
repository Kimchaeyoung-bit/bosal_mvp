# 강남보살 — E2E 검증 가이드 (P7)

베타 배포 전 모든 사이드(사용자·보살·관리자)의 골든 패스를 한 번에 도는 검증 체크리스트. 마이그레이션 적용 + 시뮬레이터·실기 + 어드민 웹 dev 서버 모두 사용.

---

## 0. 사전 적용

### 0-1. Supabase 마이그레이션 일괄 push

```bash
cd backend/supabase
supabase db push
```

추가된 마이그레이션 (이번 MVP):
- `20260424001900_extend_lookups.sql` (시드 보정)
- `20260424002000_notifications.sql` (알림 시스템)
- `20260424002100_admin_analytics.sql` (어드민 분석 RPC)
- `20260424002200_seed_inmuk_chaeyoung_bosals.sql` (데모 보살 + 계정)
- `20260424002300_notifications_rls_hardening.sql`
- `20260424002400_account_deletion.sql`
- `20260424002500_reports.sql`
- `20260424002600_broadcast_notification.sql`
- `20260424002700_view_events_and_analytics.sql`

### 0-2. admin 계정 부트스트랩

```sql
-- Supabase SQL Editor
-- bill@wadidu.com (또는 다른 admin 이메일) 가입 후
update public.profiles set role = 'admin' where id = '<auth_user_id>';
```

### 0-3. 모바일 빌드

```bash
cd apps/mobile
flutter pub get
flutter run -d <ios_simulator_id>
```

`.env`의 `DATA_SOURCE=supabase` 확인.

### 0-4. 어드민 웹 dev 서버

```bash
cd apps/admin_web
cp .env.local.example .env.local
# NEXT_PUBLIC_SUPABASE_URL / NEXT_PUBLIC_SUPABASE_ANON_KEY 입력
npm run dev
# http://localhost:3000 으로 admin 계정 로그인
```

---

## 1. 일반 사용자 골든 패스 (모바일)

| # | 액션 | 기대 결과 |
|---|---|---|
| 1 | 앱 첫 실행 | `/splash` → `/home` 자동 진입 (비로그인 OK) |
| 2 | 홈에서 카테고리 그리드 확인 | 9개 메인 + "기타" 카드 (총 10) |
| 3 | "기타" 탭 → 신년운세/궁합/꿈해몽/작명 칩 | 매칭되는 보살 표시 |
| 4 | 카테고리 한 개 (연애 등) 탭 → bosal_list | 필터된 보살 카드 |
| 5 | 보살 카드 탭 → 보살 상세 | 평점·리뷰수·연락처·소개 모두 표시 |
| 6 | (DB 확인) `bosal_view_events` insert 확인 | 5초 내 재진입은 silent skip |
| 7 | 마이페이지 → "로그인 / 회원가입" → `/login` | 로그인 화면 |
| 8 | "회원가입" 링크 → `/signup` | 가입 폼 |
| 9 | 약관·개인정보 동의 체크 X 후 가입 시도 | "이용약관과 개인정보처리방침에 모두 동의해주세요" |
| 10 | 동의 + 신규 이메일 가입 → 진입 | `/home` (일반 사용자) |
| 11 | 보살 상세 → ♡ 찜 토글 | favorites Realtime 갱신 |
| 12 | "전화 상담" 탭 (분석 이벤트 발화 + tel: 호출) | `call_events` insert 확인 |
| 13 | "예약하기" → 예약 시트 (분석 발화) | `reservation_button_events` insert 확인 |
| 14 | 시간대 선택 → 예약 확정 | `reservations` insert + 알림 트리거 |
| 15 | 알림 화면 진입 (홈 종 아이콘) | "새 예약" 도착 (보살에게 갈 알림은 보살 계정에서 확인) |
| 16 | (보살이 confirm 후) 사용자 알림 화면 | "예약 확정" 알림 도착 |
| 17 | (보살이 complete 후) 사용자 알림 화면 | "후기를 남겨주세요" 알림 |
| 18 | 알림 클릭 → deep link `/booking-tab` | 본인 예약 목록 |
| 19 | completed 예약 카드 → "후기 작성" → 별점·본문 → 저장 | reviews insert (트리거 검증 통과) |
| 20 | 마이페이지 → "내 후기" | 방금 작성한 후기 표시 |
| 21 | 마이페이지 → "찜한 보살" / "최근 본 보살" | 데이터 표시 |
| 22 | 신고 흐름 — 보살 상세 우상단 ⋯ → 신고 → 사유 선택 → 등록 | reports insert + (후기 신고 시) is_public=false |
| 23 | 마이페이지 → "이용약관" / "개인정보처리방침" 진입 | placeholder MD 렌더 |
| 24 | 마이페이지 → "회원 탈퇴" → 확인 문구 입력 → 탈퇴 | profiles deleted_at + auth banned + 자동 로그아웃 |
| 25 | 같은 이메일로 재가입 시도 | 차단 (auth banned) |

---

## 2. 보살 사장 골든 패스 (모바일)

| # | 액션 | 기대 결과 |
|---|---|---|
| 1 | 어드민에서 발급한 코드 (또는 인묵보살 시드 계정) 로그인 | role=bosal 확인 후 `/bosal-home` 자동 진입 |
| 2 | 보살 대시보드 — 받은 예약/완료/월수익 stats | 데이터 정상 |
| 3 | "보살 도구" → "보살 프로필 편집" → `/bosal-onboarding` | 폼 hydrate (시드된 정보) |
| 4 | "프로필 사진" 섹션 → 갤러리 선택 → 업로드 | Storage `bosal-images` + bosal_images row 갱신 |
| 5 | 가격·소개·운영시간 변경 후 저장 | bosals 갱신 + Realtime 반영 |
| 6 | 받은 예약 화면 (`/bosal-bookings`) | 사용자 예약 표시 |
| 7 | 예약 confirm | 상태 confirmed + 사용자에게 알림 |
| 8 | 예약 complete | 상태 completed + 사용자에게 후기 요청 알림 |
| 9 | "받은 후기" (`/bosal-reviews`) | 평균 평점 + 분포 + 후기 카드 (작성자 마스킹) |
| 10 | 후기 카드 ⋯ → 신고 | reports insert + 후기 자동 비공개 |
| 11 | 일반 사용자가 직접 `/bosal-home` 푸시 | 라우터 redirect → `/home` |

---

## 3. 관리자 골든 패스 (어드민 웹 — `localhost:3000` 또는 Vercel URL)

| # | 액션 | 기대 결과 |
|---|---|---|
| 1 | `/login` → admin 계정 입력 → 로그인 | `/` 대시보드 진입. 비-admin role은 `/login?reason=forbidden` |
| 2 | 대시보드 KPI 7개 카드 | 활성보살·전화·예약·조회·찜·예약요청·평점 |
| 3 | 24h/7d/30d 토글 | 강조 컬럼 변경 + KPI 합계 갱신 |
| 4 | 정렬 칩 6종 (전화/예약/조회/찜/평점/리뷰수) | 즉시 정렬 |
| 5 | 보살 카드 탭 → `/bosals/[id]` | 분석 사이드바 (조회/전화/예약/찜) + 편집 폼 |
| 6 | 보살 정보 변경 (가격·카테고리) → 저장 | bosals + bosal_categories 갱신 |
| 7 | publish 토글 | is_published 즉시 반영. 모바일 검색에 노출/제거 |
| 8 | `/bosals/new` → 신규 보살 + 코드 발급 | invite_code 모달 + 복사 가능 |
| 9 | `/invites` → 활성 코드 목록 + 신규 발급 폼 | v_active_bosal_invites 표시 |
| 10 | 발급한 코드를 모바일 회원가입 화면에서 입력 | role=bosal 승격 + bosal_onboarding 진입 |
| 11 | `/users` → 사용자 목록 + role 변경 | profiles update |
| 12 | `/reports?status=pending` → 신고 큐 | 모바일에서 발생한 신고 표시 |
| 13 | "유효" 처리 | reports.status=resolved + 후기 비공개 유지 |
| 14 | "기각" 처리 | reports.status=dismissed + 후기 is_public=true 복구 |
| 15 | `/notifications/new` → 대상 chip + 제목·본문 + 미리보기 → 발송 | broadcast_notification RPC 호출 + N명 결과 |
| 16 | (모바일 측) 사용자가 알림 화면 새로고침 | 방금 발송한 공지 표시 |

---

## 4. 보안 검증

| # | 시나리오 | 기대 결과 |
|---|---|---|
| S1 | 비로그인 사용자가 모바일에서 `/booking-tab` push | redirect → `/login` |
| S2 | 일반 사용자가 모바일에서 `/bosal-home` push | redirect → `/home` (라우터 가드) |
| S3 | 일반 사용자가 Supabase 직접 호출로 `update notifications set is_read=true` | RLS 차단 (RPC만 허용) |
| S4 | 비-admin이 어드민 웹 `/` 진입 | proxy.ts → `/login?reason=forbidden` + 자동 로그아웃 |
| S5 | 비-admin이 직접 `admin_list_bosal_analytics` RPC 호출 | "admin only" 에러 |
| S6 | 후기 작성자가 본인 후기에 `update reviews set is_public=true` | RLS 통과 (self) |
| S7 | 다른 사용자가 같은 후기 update 시도 | RLS 차단 |
| S8 | claim_bosal_invite 두 번 호출 | 두 번째 시도는 "invite already used" |
| S9 | 비번 재설정 — 동일 이메일 5분 내 다회 호출 | Supabase rate limit 메시지 |

---

## 5. 분석 데이터 흐름 검증

각 액션 후 어드민 대시보드 새로고침 → KPI 변동 확인:

| 액션 | KPI 영향 |
|---|---|
| 모바일에서 보살 상세 진입 | 조회 24h +1 |
| 5초 내 재진입 | +0 (rate-limit) |
| 전화 버튼 탭 | 전화 24h +1 |
| 예약 시트 진입 | 예약 24h +1 |
| 찜 토글 | 찜 +1/-1 |
| 후기 작성 | 평균 평점 / 리뷰수 갱신 |

---

## 6. 환경 분리 점검 (시나리오 C 진입 전)

- [ ] 현재 `apps/mobile/.env`의 SUPABASE_URL이 dev 인스턴스인지 확인
- [ ] prod Supabase 프로젝트 별도 생성 (시나리오 C P13)
- [ ] 데모 보살 시드 (002200) prod 적용 여부 결정 (D6)

---

## 7. 베타 진입 결정 (G5 게이트)

다음 모두 통과 시 베타 배포:

- [ ] 1, 2, 3, 4, 5 모든 케이스 통과
- [ ] Sentry 첫 이벤트 수신 확인 (DSN 설정 후 의도적 throw 한 번)
- [ ] App Store / Play Console 메타·스크린샷 입력 완료 (P6-2)
- [ ] Privacy Form 제출 (P6-3)
- [ ] TestFlight + Internal Testing 빌드 업로드 (P6-4)

게이트 통과 → 외부 베타 테스터 초대 → 1주 운영 → 정식 출시.
