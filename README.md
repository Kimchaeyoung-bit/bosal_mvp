# 강남보살 (Gangnam Bosal)

사주·상담 보살 매칭 모바일 서비스. 모노레포 구조.

## 디렉토리

```
.
├── apps/
│   └── mobile/                # Flutter 앱 (사용자 + 보살 사장)
├── backend/
│   └── supabase/              # DB 스키마·RPC·시드 (Supabase CLI 작업 디렉토리)
├── docs/                      # PRD, 설계 문서
├── prototype/                 # 초기 HTML/CSS 프로토타입 (참고용)
└── README.md                  # 이 파일
```

**`apps/admin_web/`은 이 monorepo에 없음.** 어드민 페이지는 회사의 별도 Next.js 웹 프로젝트로 운영하며, 미공개 URL로 접근. Supabase는 같은 인스턴스 공유.

## 개발

### 모바일 앱 (Flutter)

```bash
cd apps/mobile
flutter pub get
flutter run -d <device_id>
```

`.env` 가 `apps/mobile/`에 위치. `DATA_SOURCE=mock|supabase` 로 데이터 출처 토글.

### Supabase 백엔드

```bash
cd backend/supabase
supabase link --project-ref <ref>     # 최초 1회
supabase db push                       # 마이그레이션 적용
supabase db diff                       # 로컬 ↔ 리모트 비교
```

## Supabase 자산 요약

`backend/supabase/migrations/` (시간순):

| 영역 | 파일 |
|---|---|
| 부트스트랩 / 룩업 | `00..00_init.sql` ~ `00..00100_lookups.sql`, `00..001200_seed_lookups.sql`, `00..001900_extend_lookups.sql` |
| 도메인 | profiles · bosals · reservations · reviews · favorites · banner_ads · bosal_invites · bosal_ai_personas |
| 보안 | `00..000800_rls_policies.sql`, `00..001100_grants.sql` |
| RPC | `00..000900_rpcs.sql` (예약 상태 머신·invite claim), `00..001400_admin_invite_rpcs.sql`, `00..001500_bosal_profile_rpcs.sql`, `00..002100_admin_analytics.sql` |
| 알림 | `00..002000_notifications.sql` (테이블 + RLS + 트리거 + Realtime) |
| 분석 이벤트 | `00..000500_events_counters.sql` (call_events, reservation_button_events + 24h/7d/30d 집계 뷰) |
| Storage / Realtime | `00..001000_storage_realtime.sql` |
| 어드민 부트스트랩 | `00..001600_bootstrap_admin.sql`, `00..001800_admin_email_update.sql` |

## 외부 어드민 웹 통합

어드민은 외부 Next.js repo. 그쪽에서 다음 자산을 사용:

**RPC:**
- `create_bosal_invite(bosal_id, expires_days, email)`
- `create_bosal_with_invite(name, phone_display, region_code, sub_region_code, expires_days, email)`
- `admin_list_bosal_analytics()` — 보살별 24h/7d/30d 카운터 + 평점·리뷰·예약요청
- `update_bosal_owner_fields`, `replace_bosal_*`, `publish_bosal_profile` (보살 프로필 수정 — admin 권한 시 우회)

**테이블 직접 select (RLS admin 우회):**
- `v_active_bosal_invites` (활성 초대 코드 view)
- `bosal_invites`, `profiles`, `bosals`, `reservations`, `reviews`, `banner_ads`, `bosal_ai_personas`

**권한 모델:**
- `profiles.role = 'admin'` 사용자만 RPC·뷰 접근 가능 (RLS + RPC 가드).
- 부트스트랩 admin: `backend/supabase/migrations/20260424001600_bootstrap_admin.sql` 참고. 이메일은 `20260424001800_admin_email_update.sql`에서 갱신.
- 외부 어드민 web에서는 admin 계정으로 Supabase Auth 로그인 후 anon key + access token 으로 RPC 호출.

자세한 가이드: [`docs/INTEGRATION.md`](docs/INTEGRATION.md).

## 후속 과제

- 공유 Dart 패키지화 (모바일·어드민 공유 모델·datasource).
- CI/CD: GitHub Actions로 `apps/mobile` 빌드 + `backend/supabase` 마이그레이션 push.
- 결제 / AI 챗봇 (별도 제품 결정 후).
