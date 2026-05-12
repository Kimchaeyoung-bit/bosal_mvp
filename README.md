# 강남보살 (Gangnam Bosal)

지역·전문분야 기반으로 보살과 사용자를 연결하고 예약·후기까지 한 번에 잇는 플랫폼. **모노레포** 구조 — 모바일 앱 + Supabase 백엔드 + 외부 어드민 웹(별도 repo).

```
.
├── apps/
│   └── mobile/             # Flutter 앱 (사용자 + 보살 사장)
├── backend/
│   └── supabase/           # DB 스키마·RPC·시드 (Supabase CLI 작업 디렉토리)
├── docs/
│   ├── PRD.md              # 현재 구현 상태 반영 PRD
│   └── INTEGRATION.md      # 외부 어드민 웹 ↔ Supabase 통합 가이드
├── prototype/              # 초기 HTML/CSS 프로토타입 (역사 자료)
└── README.md               # 이 파일
```

> **`apps/admin_web/`은 이 monorepo에 없습니다.** 어드민 페이지는 회사의 별도 Next.js 웹 프로젝트(미공개 URL)에서 운영하며, 같은 Supabase 인스턴스를 공유합니다. 통합 가이드: [`docs/INTEGRATION.md`](docs/INTEGRATION.md).

---

## 빠른 시작

### 1) 모바일 앱 (Flutter)

```bash
cd apps/mobile
cp .env.example .env          # 값 채워 넣기
flutter pub get
flutter run -d <device_id>    # `flutter devices` 로 device_id 확인
```

상세 가이드: [`apps/mobile/README.md`](apps/mobile/README.md).

### 2) Supabase 백엔드

```bash
cd backend/supabase
supabase link --project-ref <ref>     # 최초 1회
supabase db push                       # 마이그레이션 적용
supabase db diff                       # 로컬 ↔ 리모트 비교
```

마이그레이션은 `migrations/` 폴더의 파일명 시간순 자동 적용 (idempotent 패턴 사용).

---

## 핵심 흐름 (한눈에)

| 사이드 | 채널 | 진입 |
|---|---|---|
| 사용자 (찾는 사람) | 모바일 앱 | 스플래시 → 홈 → 카테고리/지역/검색 → 보살 상세 → 예약 시트 → 후기 작성 |
| 보살 사장 (받는 사람) | 모바일 앱 (`/bosal-*` 탭) | 초대 코드 claim → 온보딩 → 대시보드(예약·후기·프로필) |
| 관리자 | 외부 Next.js 웹 | Supabase Auth → admin role 검증 → 보살 초대 발급·분석·공지 |

자세한 사용자 흐름과 도메인 매핑: [`docs/PRD.md`](docs/PRD.md).

---

## 백엔드 자산 요약

`backend/supabase/migrations/` (시간순):

| 영역 | 파일 |
|---|---|
| 부트스트랩 | `20260424000000_init.sql` |
| 룩업 / 시드 | `00..00100_lookups.sql`, `00..001200_seed_lookups.sql`, `00..001900_extend_lookups.sql` |
| 도메인 | profiles · bosals(+children) · reservations · reviews · favorites · banner_ads · bosal_invites · bosal_ai_personas |
| 보안 | `00..000800_rls_policies.sql`, `00..001100_grants.sql` |
| RPC | `00..000900_rpcs.sql` (예약 상태 머신·invite claim), `00..001400_admin_invite_rpcs.sql`, `00..001500_bosal_profile_rpcs.sql`, `00..002100_admin_analytics.sql` |
| 알림 | `00..002000_notifications.sql` (테이블 + RLS + 트리거 + Realtime) |
| 분석 이벤트 | `00..000500_events_counters.sql` (call_events / reservation_button_events + 24h/7d/30d 집계 뷰) |
| Storage / Realtime | `00..001000_storage_realtime.sql` |
| 어드민 부트스트랩 | `00..001600_bootstrap_admin.sql`, `00..001800_admin_email_update.sql` |
| 데모 보살 시드 | `00..002200_seed_inmuk_chaeyoung_bosals.sql` |

자세한 권한 매트릭스 / RPC 시그니처 / 환경변수: [`docs/INTEGRATION.md`](docs/INTEGRATION.md).

---

## 데모 자격증명

`DATA_SOURCE=mock` 모드 (오프라인 검증용):

| 역할 | ID / 비번 |
|---|---|
| 일반 사용자 | `a` / `1234` |
| 보살 사장 | `b` / `1234` |

`DATA_SOURCE=supabase` 모드: 운영 보살 계정은 어드민 웹의 초대 코드 흐름(`/bosals/new`)으로 생성. admin 부트스트랩은 [`backend/supabase/.env.example`](backend/supabase/.env.example) 의 `ADMIN_EMAIL` 변수 + [`docs/RELEASE_CHECKLIST.md`](docs/RELEASE_CHECKLIST.md) 절차 참고.

---

## 후속 과제

- 모바일 / 외부 어드민 공유 Dart·TypeScript 패키지 (모델·DTO·RPC 호출 클라이언트 자동생성)
- CI/CD: GitHub Actions로 `apps/mobile` 빌드 + `backend/supabase` 마이그레이션 push 자동화
- 결제 / AI 챗봇 (별도 제품 결정 후 진입)
- 어드민 공지 일괄 발송 RPC 신설 (`broadcast_notification`)

전체 우선순위 검토: [`docs/PRD.md`](docs/PRD.md) §9.
