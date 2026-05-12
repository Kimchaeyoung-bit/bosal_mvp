# 강남보살 — 서비스 PRD

> 본 문서는 현재 구현된 1차 MVP 상태를 반영한 작업용 PRD. 초기 기획 원본은 [`prototype/docs/PRD.md`](../prototype/docs/PRD.md).

---

## 1. 서비스 개요

- **앱명**: 강남보살 (Gangnam Bosal)
- **정체성**: 지역·전문분야 기반으로 실제 활동 중인 보살과 사용자를 연결하고, 예약·후기까지 한 흐름으로 잇는 모바일 플랫폼
- **타깃**:
  - 1차: 20~40대, 연애·진로·인간관계 고민 보유, 점·사주 경험 있는 사용자
  - 2차: 검증된 보살을 찾기 어려운 지방 거주자
- **벤치마크**: 강남언니(전문가 매칭·예약), 쏘카(위치 중심 UX)

---

## 2. 서비스 구성 (3 사이드)

| 사이드 | 채널 | 위치 | 역할 |
|---|---|---|---|
| **사용자(고객)** | 모바일 앱 | `apps/mobile/` | 보살 탐색·필터·예약·후기 작성·찜·알림 |
| **보살(사장)** | 모바일 앱 (같은 앱, 별도 탭 셋) | `apps/mobile/` (`/bosal-*`) | 받은 예약 관리, 본인 프로필 편집, 후기 모니터링 |
| **관리자** | 외부 Next.js 웹 (회사 별도 repo) | 미공개 URL | 보살 초대 코드 발급·분석 대시보드·시스템 공지 |

같은 Supabase 인스턴스를 3 사이드가 공유. RLS·RPC 가드로 권한 분리. 관리자 화면은 모바일에 **없음**.

---

## 3. 핵심 가치 제안

1. **나에게 맞는 보살** — 카테고리(연애·재물·진로·인간관계·타로·사업·신년운세·궁합·꿈해몽·작명·기타) × 지역(전국 16개 시도, 강남 11개 권역 포함) × 상담 스타일(직설·공감·냉철) 기반 필터.
2. **검증 가능한 정보** — 한 줄 소개·경력·운영시간·평점·후기·연락처를 한 화면에. 별점 분포(1~10점, 5★ 버킷 시각화).
3. **원스톱 흐름** — 탐색 → 상세 → 예약 시트(채널 선택, 날짜·시간) → 상태 추적(pending → confirmed → completed) → 후기 작성.

---

## 4. 사용자 흐름 (현재 구현)

### 4-1. 일반 사용자

```
스플래시
  ↓
[로그인 / 회원가입] (선택, 비로그인도 탐색 가능)
  ↓
홈 (인사 헤더 · 카테고리 그리드 9+1 · 인기 보살 · 지역 선택 · 운세 · 알림)
  ├─→ 카테고리 탭 → 보살 리스트 (필터)
  ├─→ "기타" → 기타 카테고리 (4 칩)
  ├─→ 검색 → 검색 화면 (검색어·최근 검색)
  ├─→ 지도 (region_tab) → 지역별 마커 + 시트
  └─→ 보살 카드 → 보살 상세 → 예약 시트
                                   ↓
                          예약 생성 (createPending)
                                   ↓
                          예약 내역 / 알림 (Realtime)
                                   ↓
                          상담 완료 → 후기 작성 (별점·본문·공개 여부)
```

마이페이지: 예약 내역 / 찜한 보살 / 최근 본 보살 / 내 후기 / 보살 도구(보살 role 시) / 고객 지원.

### 4-2. 보살 사장

```
초대 코드 수신 (관리자 발급)
  ↓
회원가입 → 코드 입력 → role=bosal 승격
  ↓
보살 온보딩 (프로필·가격·주소·운영시간·카테고리·특징)
  ↓
publish (is_published=true)
  ↓
보살 대시보드 (stats: 대기/확정/완료/월수익)
  ├─ 받은 예약 → confirm / reject / complete (RPC)
  ├─ 받은 후기 (공개 후기 + 평점 분포)
  └─ 본인 프로필 편집
```

### 4-3. 관리자 (외부 웹)

```
Supabase Auth 로그인 (admin role)
  ├─ 보살 초대 코드 발급 (create_bosal_invite / create_bosal_with_invite)
  ├─ 분석 대시보드 (admin_list_bosal_analytics: 24h/7d/30d 카운터)
  ├─ 보살·예약·후기 직접 조회 (admin RLS 우회)
  └─ 시스템 공지 발송 (현재는 직접 insert. broadcast RPC 신설 예정)
```

---

## 5. 보살 프로필 데이터 모델

| 필드 | 의미 | 비고 |
|---|---|---|
| name / one_liner / description | 활동명·한 줄 소개·상세 | name 필수 |
| experience_years | 경력 연차 | check ≥ 0 |
| consult_style | 상담 스타일 | cool · empathetic · direct |
| phone_display / phone_e164 | 연락처 | E.164 검증 |
| original_price / discounted_price / first_visit_price / max_points | 가격 정책 | discount_percent 자동 계산 |
| sido / sigungu / eupmyeondong / road_address | 구조화 주소 | |
| region_id / sub_region_id | 지역 FK (단수) | mock의 List는 client-side 필터에서 사용 |
| location | PostGIS Point | 지도 마커 |
| ad_intent_tier | 광고 의향 | none · interested · active_campaign |
| rating_avg · review_count · qna_count · call_count · reservation_button_count · consult_request_count | denorm 카운터 | 트리거가 자동 갱신 |
| is_published | 공개 여부 | 온보딩 완료 후 true |
| 자식 1:N: bosal_features (특징), operating_hours (요일별), bosal_images (사진) |
| 자식 M:N: bosal_categories |

---

## 6. 도메인 영역별 구현 상태

| 영역 | 백엔드 | 모바일 화면 | 상태 |
|---|---|---|---|
| 인증 / 세션 | Supabase Auth + profiles 자동 생성 트리거 + claim_bosal_invite RPC | login, signup | ✅ |
| 보살 탐색 / 필터 | bosals nested select + bosal_categories M:N + 클라이언트 필터 | home, bosal_list, other_category, search, map, region_tab | ✅ |
| 예약 (state machine) | reservations + 4 RPC + Realtime publication | booking_sheet, booking_screen, my_activity/bookings | ✅ |
| 찜 | favorites M:N + Realtime stream | bosal_detail 토글, my_activity/favorites | ✅ |
| 알림 | notifications 테이블 + 트리거 자동 발송(예약·후기) + Realtime + read RPC | notifications_screen, 홈 종 아이콘 | ✅ |
| 후기 | reviews + completed 예약 검증 트리거 + 평점 자동 갱신 트리거 | review_compose, my_activity/reviews, bosal_reviews(보살 대시보드) | ✅ |
| 보살 온보딩 / 프로필 편집 | update_bosal_owner_fields + replace_* + publish RPC | bosal_onboarding, bosal_profile (보살 대시보드) | ✅ (UI 일부 폴리싱 필요) |
| 보살 초대 / 관리자 발급 | bosal_invites + create_bosal_invite / create_bosal_with_invite RPC + v_active_bosal_invites view | (외부 어드민 웹에서 운영 — 모바일 미노출) | ✅ 백엔드, 외부 UI 작업 중 |
| 분석 이벤트 | call_events / reservation_button_events + 24h/7d/30d 집계 뷰 | analyticsDataSource (전화·예약 버튼 탭 시 발화) | 🟡 화면 콜사이트 검증 필요 |
| 어드민 분석 대시보드 | admin_list_bosal_analytics RPC | (외부 어드민 웹) | ✅ 백엔드, 외부 UI 작업 중 |
| 운세 | (정적) | fortune_screen | 🟡 정적 콘텐츠 |
| 챗봇 | bosal_ai_personas (scaffold) | chatbot_screen (placeholder) | ⏳ 미구현 |
| 결제 | payment_status 컬럼만 | — | ⏳ PG 미연동 |
| 광고 배너 | banner_ads + 시간대 필터 | 홈 정적 placeholder만 | ⏳ |
| 포인트 / 멤버십 | max_points 컬럼만 | — | ⏳ |

---

## 7. 데이터 시드 현황

- **카테고리**: 메인 7개(연애·취업·재물·건강·인간관계·타로·사업) + 기타 4개(신년운세·궁합·꿈해몽·작명).
- **지역**: 전국 16개 시도, sub_regions 130여 개 (좌표 포함).
- **보살 계정**: 시드 미포함. 어드민 웹의 초대 코드 흐름으로 운영 시점에 생성.

## 8. 신뢰 / 안전 설계

- **RLS fail-closed**: 전 테이블 default deny, 명시 정책만 허용. RPC는 SECURITY DEFINER + 호출자 권한 검증.
- **completed 예약 강제**: 후기 insert 트리거가 본인의 completed 예약 보유 여부 확인. admin은 우회.
- **rate-limit 트리거**: call_events / reservation_button_events 3초 내 중복 차단.
- **invite one-time**: bosal_invites는 used_at·expires_at 검증 후 단 한 번만 claim 가능.
- **개인정보 마스킹**: 후기 작성자 표시명은 모바일 단에서 마스킹 (`김**`).

---

## 9. 후속 과제 (우선순위 검토용)

| Tier | 항목 | 상태 |
|---|---|---|
| 1 | sub_region M:N 모델 결정 (현재 단수 FK ↔ mock의 List 불일치) | 미결정 |
| 1 | dev seed (`20260424001300_seed_bosals_dev.sql`) prod 분리 | 미결정 |
| 1 | broadcast_notification RPC 신설 (관리자 공지 발송) | 미구현 |
| 2 | 결제 (PG·환불 흐름 설계) | 미시작 |
| 2 | AI 챗봇 / 운세 (LLM 통합) | 미시작 |
| 2 | CI/CD (모바일 빌드 + 마이그레이션 push 자동화) | 미시작 |
| 3 | 모바일·외부 어드민 공유 Dart 패키지 | 미시작 |
| 3 | 후기 분석 자동 요약 / AI 추천 고도화 | 미시작 |
| 3 | 광고 배너 운영 도구 / 포인트 시스템 | 보류 |

---

## 10. 관련 문서

- 모노레포 구조 / 개발 명령 → [워크스페이스 README](../README.md)
- 모바일 앱 구조 / DataSource 패턴 → [`apps/mobile/README.md`](../apps/mobile/README.md)
- 외부 어드민 웹 ↔ Supabase 통합 → [`docs/INTEGRATION.md`](INTEGRATION.md)
- 초기 기획 원본 (HTML 프로토타입 시점) → [`prototype/docs/PRD.md`](../prototype/docs/PRD.md)
