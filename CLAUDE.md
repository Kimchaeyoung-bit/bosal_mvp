# Claude Working Rules — 강남보살 모노레포

## 🚨 가장 중요한 규칙

**모든 작업이 끝나면 [`task.md`](task.md)를 갱신해야 한다.** 단순 한 줄 수정도, 큰 Phase 완료도, 모두 task.md 반영. 사용자가 진행 상황을 한눈에 보기 위함.

업데이트 형식:
- **🟢 완료(Done)**: 체크박스 `[x]` + 어떤 Phase·작업번호 + (가능하면) commit hash
- **🟡 진행 중(In Progress)**: 현재 작업 중인 단일 항목, 어디까지 됐는지 간략 메모
- **🔴 할 일(Todo)**: 마스터 플랜 기준 남은 작업
- **🟣 사용자 결정 대기 / 외부 준비**: 우리가 진행 못 하는 외부 의존 항목

작성 후 git에 staging 추가는 하되 자동 commit은 금지. 사용자 검토 후 commit 결정.

---

## 프로젝트 개요

모노레포. `apps/mobile/` (Flutter), `backend/supabase/` (마이그레이션), 추후 `apps/admin_web/` (Next.js).
자세한 구조: [README.md](README.md).
PRD: [docs/PRD.md](docs/PRD.md).
외부 어드민 통합: [docs/INTEGRATION.md](docs/INTEGRATION.md).
마스터 플랜: `~/.claude/plans/jiggly-gliding-clock.md`.

## 작업 위치

- **모바일** (Flutter): 항상 `apps/mobile/`에서 작업
  - `flutter pub get`, `flutter analyze`, `flutter run` 모두 이 디렉토리에서
- **백엔드** (Supabase): 마이그레이션은 `backend/supabase/migrations/` 에 시간순(`YYYYMMDDHHMMSS_*.sql`)
  - `supabase db push`는 `backend/supabase/` 에서
- **어드민 웹** (예정): `apps/admin_web/`. 아직 미생성.

## 코딩 규칙

### Flutter
- DataSource 패턴 유지 — 추상 + Mock + Supabase 두 구현. `data_source_providers.dart` 통해 `.env`의 `DATA_SOURCE` 토글.
- 모든 비동기 데이터 접근은 `AsyncValue.when(data:..., loading:..., error:...)` 또는 maybeWhen + 빈 상태 fallback.
- 새 화면 추가 시 라우터에 path 등록 + 인증 가드 (`appRouterProvider`의 redirect 또는 화면 자체 가드).
- 모델 변경 시 `fromMap` 갱신 + Supabase 스키마 일치 확인.
- 주석 최소화 — 의도가 비명확한 부분만.

### Supabase
- 모든 새 테이블은 RLS enable + 명시적 정책 (fail-closed).
- 사용자 호출 RPC는 `security definer` + `set search_path = public` + `grant execute to authenticated`.
- 마이그레이션은 idempotent — `if not exists`, `on conflict do nothing/update`.
- 트리거는 의도와 트랜잭션 안전성 명시 주석.

### 커밋
- BLOCKER/HIGH/MEDIUM 등 우선순위 단위로 묶음 commit.
- Co-Authored-By 항상 추가.
- 메시지 한국어 OK.

## 보안

- `.env`는 모바일은 `apps/mobile/`, 운영자 부트스트랩 변수는 `backend/supabase/`에 위치, 둘 다 git ignore. `.env.example`만 commit.
- 시크릿(SUPABASE_ANON_KEY, ADMIN_EMAIL 등) 하드코딩 금지.
- 평문 비밀번호·실 이메일을 마이그레이션에 박지 않는다. 운영 보살 계정은 어드민 초대 코드 흐름으로 생성.

## 결정 / 가정

마스터 플랜의 D1~D8 결정 항목. 기본값에서 벗어나는 결정 통지 시 즉시 분기. 현재 확정:
- D1 = A (어드민 웹 monorepo `apps/admin_web/` Next.js)
- D3 = 미포함 (MVP에서 푸시 알림 제외, 시나리오 C에서 추가)

## 자주 쓰는 명령

```bash
# Flutter
cd apps/mobile && flutter pub get && flutter analyze
cd apps/mobile && flutter run -d <device_id>

# Supabase
cd backend/supabase && supabase db push
cd backend/supabase && supabase db diff

# Git
git status --short
git log --oneline -10
```

## 외부 어드민 연동

`profiles.role = 'admin'` 사용자만 admin RPC 사용 가능. RLS · RPC가 모두 `is_admin()` 헬퍼로 검증. admin 부트스트랩은 [`backend/supabase/.env`](backend/supabase/.env.example) 의 `ADMIN_EMAIL` 변수 기준으로 운영자가 Supabase SQL Editor 에서 직접 승격한다 (`backend/supabase/scripts/print_bootstrap_admin_sql.sh` 출력 활용). 마이그레이션 [001600](backend/supabase/migrations/20260424001600_bootstrap_admin.sql)·[001800](backend/supabase/migrations/20260424001800_admin_email_update.sql) 은 no-op.

---

다시 강조: **작업 완료 → task.md 업데이트 → 사용자에게 보고**. 빠뜨리지 말 것.
