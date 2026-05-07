# 강남보살 — 작업 트래커

마스터 플랜: [`~/.claude/plans/jiggly-gliding-clock.md`](file:///Users/mook/.claude/plans/jiggly-gliding-clock.md)

업데이트 규칙: 작업이 끝날 때마다 항상 본 파일을 갱신 (CLAUDE.md 지시).

---

## 🟢 완료 (Done)

### Phase 0 — 사전 준비
- [x] `feat/mvp-launch` 브랜치 분기 (commit `72dd025` baseline)
- [x] 미커밋 문서·시드 baseline commit

### Phase 1 — 모바일 BLOCKER + HIGH 묶음 (commit `50f47d1`)
- [x] **P1-1** iOS Info.plist 권한 description (위치/카메라/사진/한국어 앱 이름/tel·https 스킴)
- [x] **P1-1** Android Manifest 권한 (INTERNET·위치·미디어·알림·카메라) + tel/https/http intent
- [x] **P1-2** GoRouter `appRouterProvider` + redirect 가드 (보살 라우트·인증 필요·로그인 후 차단)
- [x] **P1-3** booking_screen mockBosals.first crash → `allBosalsProvider` + `_BookingCardSkeleton` fallback
- [x] **P1-4** 분석 이벤트 발화 — `logCallTap` (전화 버튼) + `logReservationButtonTap` (예약 시트 진입)
- [x] **P1-5** `AuthNotifier.login` → `({error, user})` record 반환 (state race 회피)
- [x] **P1-5** booking_sheet 시간대별 가격 적용 (`_selectedSlot.price`)
- [x] **P1-5** review_compose 에러 메시지 친화 분기 (raw exception 차단)
- [x] **P1-6** `20260424002300_notifications_rls_hardening.sql` — self update 정책 → admin-only

### Phase 2 — 약관·탈퇴·신고 (commit `e336fb0`)
- [x] **P2-1** 약관·개인정보 화면 — `flutter_markdown` + placeholder `terms.md`/`privacy.md` + `LegalDocumentScreen` + 라우트 (`/legal/terms`, `/legal/privacy`) + mypage 메뉴 + signup 동의 체크박스(필수 2개)
- [x] **P2-2** 회원 탈퇴 — `20260424002400_account_deletion.sql` (`delete_my_account` RPC, anonymize + auth ban) + `AccountDeleteScreen` (`/account/delete`) + mypage 메뉴
- [x] **P2-3** 신고 시스템 — `20260424002500_reports.sql` (테이블 + RLS + 후기 자동 비공개 트리거 + `resolve_report` admin RPC) + `showReportDialog` + 보살 상세 PopupMenu + 보살 대시보드 후기 카드 PopupMenu
- [x] CLAUDE.md 작성 — task.md 갱신 규칙
- [x] task.md 작성 — 작업 트래커

### Phase 3 — 어드민 웹 (`apps/admin_web/` Next.js 16 + React 19)
- [x] **P3-1** create-next-app + Tailwind v4 + Supabase SSR scaffold
- [x] **P3-2** Supabase Auth + admin role 가드 (Next 16 `proxy.ts` — middleware 후신)
- [x] **P3-3** 대시보드 — `admin_list_bosal_analytics` RPC 시각화 (KPI 7개 + 보살별 테이블 + 24h/7d/30d 토글 + 정렬 칩 6종)
- [x] **P3-4** 보살 관리 — `/bosals` 목록·검색·필터, `/bosals/new` 신규(create_bosal_with_invite + 코드 복사 모달), `/bosals/[id]` 편집(update_owner_fields + replace_categories + publish 토글)
- [x] **P3-5** 초대 코드 관리 — `/invites` (v_active_bosal_invites 목록 + create_bosal_invite 발급 폼)
- [x] **P3-6** 사용자 관리 — `/users` (검색·role 필터·인라인 role 변경 + confirm)
- [x] **P3-7** 신고 큐 — `/reports?status=pending|resolved|dismissed` (resolve_report RPC: 유효/기각 처리)
- [x] **P3-8** 공지 발송 페이지 — `/notifications/new` (대상 chip + 미리보기 + confirm 모달)
- [x] **AdminShell** 공용 nav 레이아웃 (대시보드/보살/초대/사용자/신고/공지)
- [ ] **P3-9** Vercel 배포 + Password Protection (외부 사용자 작업)

### Phase 4 — 어드민 공지 + 분석 확장 + In-App 알림 (commit `b2156d8`)
- [x] **P4-1** `20260424002600_broadcast_notification.sql` — admin 공지 일괄 발송 RPC
- [x] **P4-2** 분석 확장 — `20260424002700_view_events_and_analytics.sql`:
  · `bosal_view_events` 테이블 + RLS + 5초 rate-limit 트리거
  · `v_bosal_view_stats` 24h/7d/30d/total 집계 뷰
  · `admin_list_bosal_analytics` 재정의 — view_*4개 + favorite_count 추가
- [x] **P4-2** 모바일 `analytics_data_source.logBosalView` 추가 + 보살 상세 진입 시 발화
- [x] **P4-2** 어드민 대시보드 — 조회/찜 KPI 카드 + 정렬 칩 + 테이블 컬럼 + 보살 상세 사이드바 분석 카드
- [⏸] **P4-3** 위치 권한 안내 화면 — 실제 위치 사용 기능 도입 시 함께 추가 (현재 region_tab은 보살 좌표만 표시, 사용자 위치 미사용)

### Phase 5 — 신뢰성 (commit `fbdb90d`)
- [x] **P5-1** 비밀번호 재설정 — `PasswordResetScreen` (`/auth/password-reset`) + `resetPasswordForEmail` 호출 + 로그인 화면 진입 링크
- [x] **P5-2** 보살 프로필 사진 업로드 — `image_picker` 의존성 + `ProfileImagePicker` 위젯 + Storage `bosal-images` upsert + `bosal_images` 테이블 갱신 + onboarding 화면 통합
- [x] **P5-3** 세션 만료 — 기존 `authProvider` stream + GoRouter redirect 가드로 자동 처리됨 (별도 작업 불필요)
- [x] **P5-4** Sentry — `sentry_flutter` 의존성 + main `SentryFlutter.init` (DSN 미설정 시 비활성) + `.env`/`.env.example`에 `SENTRY_DSN` 추가

### Phase 7 — E2E 검증 가이드
- [x] [`docs/E2E_VERIFICATION.md`](docs/E2E_VERIFICATION.md) — 사이드별 골든 패스 / 보안 검증 / 분석 흐름 / G5 게이트 체크리스트
- [⏳] **P7** 마이그레이션 push + 사이드 3개 골든 패스 실주행 (사용자 + 시뮬레이터)

### Phase 6 — 출시 자산 (코드 자동화 설정 완료, 자산은 사용자 작업)
- [x] pubspec에 `flutter_launcher_icons` / `flutter_native_splash` 설정 등록 — `assets/launcher/icon-1024.png` + `splash.png` 만 두면 `dart run` 한 번으로 적용
- [x] [`docs/RELEASE_CHECKLIST.md`](docs/RELEASE_CHECKLIST.md) — 전 출시 절차 (아이콘·스플·스토어 메타·Privacy form·키스토어·심사 데모 계정·Vercel 어드민 배포·사전 점검 체크리스트)
- [⏳] **P6-1** 디자인팀에서 final 아이콘·스플 자산 수신 후 명령 실행 (사용자)
- [⏳] **P6-2** App Store Connect / Play Console 메타 입력 (사용자)
- [⏳] **P6-3** Privacy Nutrition Label / Data Safety Form 제출 (사용자)
- [⏳] **P6-4** TestFlight + Internal Testing 첫 빌드 업로드 (사용자)

### Phase 5 — 신뢰성
- [ ] **P5-1** 비밀번호 재설정 화면 (`resetPasswordForEmail`)
- [ ] **P5-2** 사진 업로드 UI (보살 프로필 → Storage `bosal-images`)
- [ ] **P5-3** 세션 만료 / 자동 로그아웃 (`onAuthStateChange` 전역 구독)
- [ ] **P5-4** Sentry 통합 (`sentry_flutter` + DSN)

### Phase 6 — 출시 자산
- [ ] **P6-1** 앱 아이콘 final 1024×1024 + 스플래시 (`flutter_launcher_icons`, `flutter_native_splash`)
- [ ] **P6-2** App Store Connect / Play Console 메타 (이름·설명·키워드·스크린샷)
- [ ] **P6-3** Privacy Nutrition Label / Data Safety Form
- [ ] **P6-4** TestFlight + Internal Testing 배포

### Phase 7 — 검증
- [ ] **P7** E2E 골든 패스 (사용자·보살·관리자 3 사이드)

---

## 🟣 사용자 결정 대기 / 외부 준비

| ID | 항목 | 상태 |
|---|---|---|
| D1 | 어드민 웹 위치 | ✅ A monorepo 확정 |
| D3 | MVP 푸시 포함 | ✅ 미포함 (시나리오 C로) |
| D2 | 지도 포함 | 기본값 포함 진행 |
| D4 | 약관·개인정보 본문 | placeholder MD 두고 사내 작성 병행 |
| D5 | 회원 탈퇴 정책 | 기본값 anonymize 진행 |
| D6 | 인묵·채영 시드 | 기본값 dev only 분기 (P8) |
| D7 | 결제 MVP | 기본값 미포함 |
| D8 | 신고 정책 | 기본값 즉시 비공개 + 검토 후 복구 |

| 외부 | 필요 시점 | 상태 |
|---|---|---|
| 시뮬레이터 부트 (P1 smoke test) | 즉시 | ⏳ 대기 |
| Vercel 계정 + GitHub 연결 | Day 4 (P3-9) | ⏳ |
| App Store Connect / Play Console | Day 5 (P6-2) | ⏳ |
| 앱 아이콘 final 디자인 | Day 5 (P6-1) | ⏳ |
| 약관/개인정보 본문 | Day 5 (P6 직전) | ⏳ |
| Supabase admin 비번 (`bill@wadidu.com`) | Day 3 (P3-2) | ⏳ |

---

## 🔮 시나리오 C (정식 출시 후)

- 푸시 알림 (FCM/APNs) — P11-PUSH (1주)
- CI/CD (GitHub Actions)
- Production Supabase 분리
- 공유 타입 패키지
- i18n / a11y / 단위 테스트 / 다크모드
