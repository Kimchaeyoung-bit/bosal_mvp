# 강남보살 — 모바일 앱

> 강남보살 모노레포의 Flutter 앱 패키지. 사용자(찾는 사람)와 보살 사장(받는 사람)이 같은 앱에서 다른 흐름으로 진입.

이 README는 `apps/mobile/` 패키지 한정. 모노레포 전반 안내는 [워크스페이스 루트 README](../../README.md), Supabase 백엔드는 [`backend/supabase/`](../../backend/supabase/), 외부 어드민 통합은 [`docs/INTEGRATION.md`](../../docs/INTEGRATION.md) 참고.

---

## 기술 스택

| 영역 | 사용 기술 |
|---|---|
| 프레임워크 | Flutter (Dart `^3.7.0`), iOS / Android / Web |
| 상태 관리 | `flutter_riverpod` (StateNotifier · FutureProvider · StreamProvider 혼합) |
| 라우팅 | `go_router` (StatefulShellRoute 사용자/보살 듀얼 탭) |
| 백엔드 | `supabase_flutter` (Auth · PostgREST · Realtime · Storage) |
| 지도 | `flutter_map` + OpenStreetMap |
| 환경 변수 | `flutter_dotenv` |
| 기타 | `google_fonts`, `flutter_svg`, `url_launcher`, `intl` |

---

## 구조

```
apps/mobile/
├── lib/
│   ├── main.dart                  # 엔트리 (.env 로드 + Supabase 초기화)
│   ├── app.dart                   # MaterialApp + GoRouter
│   ├── core/
│   │   ├── router/                # GoRouter 라우트 정의
│   │   ├── supabase/              # Supabase 클라이언트 부트스트랩
│   │   ├── theme/                 # 색상·타이포·테마
│   │   ├── constants/             # 앱 상수
│   │   └── utils/auth_guard.dart  # 인증 필요 액션 헬퍼
│   ├── data/
│   │   ├── models/                # POJO + fromMap (Bosal, Reservation, Review, Notification, AppUser …)
│   │   ├── datasources/           # 추상 DataSource + Mock + Supabase 두 구현
│   │   └── mock/                  # 오프라인 mock 데이터 (DATA_SOURCE=mock 시 사용)
│   ├── providers/                 # Riverpod providers
│   ├── features/                  # 화면 단위 기능 (아래 표 참고)
│   └── shared/widgets/            # 공용 위젯 (Scaffold, EmptyState …)
├── assets/                        # 이미지·SVG
├── web/                           # Flutter Web 빌드 타깃
├── ios/  android/  macos/  linux/  windows/
├── pubspec.yaml
├── .env / .env.example
└── analysis_options.yaml
```

### 기능 화면 (라우트 ↔ 파일)

| 흐름 | 라우트 | 화면 |
|---|---|---|
| 진입 | `/splash`, `/login`, `/signup` | splash, login, signup |
| 사용자 탭 | `/home`, `/region-tab`, `/booking-tab`, `/my-tab` | home, region_tab(map), booking, mypage |
| 검색·필터 | `/search`, `/region-select`, `/bosal-list`, `/other-categories`, `/map` | search, region/region_selection, bosal_list, bosal_list/other_category, map |
| 보살 상세 / 예약 | `/bosal/:id`, `/booking-tab` (booking_sheet 모달) | bosal_detail, booking |
| 마이 | `/my/bookings`, `/my/favorites`, `/my/recent`, `/my/reviews` | my_activity (4 type 분기) |
| 부가 | `/notifications`, `/fortune`, `/chatbot` | notifications, fortune, chatbot |
| 후기 작성 | `/review/compose?bosalId=&reservationId=` | review/review_compose |
| 보살 사장 탭 | `/bosal-home`, `/bosal-bookings`, `/bosal-reviews`, `/bosal-profile` | bosal_dashboard 4개 |
| 온보딩 | `/bosal-onboarding` | bosal_onboarding (초대 claim 직후) |

어드민 화면은 이 앱에 **없음** — 외부 Next.js 웹에서 운영. 자세한 내용은 [`docs/INTEGRATION.md`](../../docs/INTEGRATION.md).

---

## DataSource 패턴

`.env`의 `DATA_SOURCE=mock|supabase` 로 데이터 출처 토글. 모든 도메인에 추상 인터페이스 + 두 구현체.

| Provider | Mock | Supabase |
|---|---|---|
| `bosalDataSourceProvider` | `mock_bosals.dart` | nested PostgREST select + 5개 RPC |
| `reservationDataSourceProvider` | in-memory store | insert + 4 RPC + Realtime stream |
| `authDataSourceProvider` | `TEST_USER_*` / `TEST_BOSAL_*` env | Supabase Auth + profile hydration |
| `notificationDataSourceProvider` | seed 4건 | RPC + Realtime stream |
| `reviewDataSourceProvider` | 8건 mock | direct insert(트리거 검증) + select |
| `favoriteDataSourceProvider` | Map<uid,Set> | upsert + Realtime stream |
| `category/region/banner_ad/analyticsDataSourceProvider` | mock | 표준 select / insert |

스위치는 [`lib/providers/data_source_providers.dart`](lib/providers/data_source_providers.dart) 한 곳.

---

## 시작하기

### 1. 사전 요구사항

- Flutter SDK `^3.7.0`
- Xcode (iOS) / Android Studio (Android) / Chrome (Web)
- Supabase 프로젝트 (테스트용 dev 인스턴스 OK)

### 2. 의존성 설치

```bash
cd apps/mobile
flutter pub get
```

### 3. 환경 변수

`.env.example` 복사 후 값 채움:

```bash
cp .env.example .env
```

| Key | 설명 |
|---|---|
| `DATA_SOURCE` | `mock` 또는 `supabase`. 기본값 `supabase` |
| `SUPABASE_URL` | Supabase 프로젝트 URL |
| `SUPABASE_ANON_KEY` | Supabase anon public key |
| `TEST_USER_USERNAME` / `TEST_USER_PASSWORD` | mock 모드 일반 사용자 (기본 `a` / `1234`) |
| `TEST_BOSAL_USERNAME` / `TEST_BOSAL_PASSWORD` | mock 모드 보살 사장 (기본 `b` / `1234`) |
| `BOSAL_INMUK_EMAIL` / `BOSAL_INMUK_PASSWORD` | supabase 모드 데모 보살 (인묵, `inmuk@bosal.test` / `bosal1234`) |
| `BOSAL_CHAEYOUNG_EMAIL` / `BOSAL_CHAEYOUNG_PASSWORD` | supabase 모드 데모 보살 (채영, `chaeyoung@bosal.test` / `bosal1234`) |

> 데모 보살 자격증명은 [`backend/supabase/migrations/20260424002200_seed_inmuk_chaeyoung_bosals.sql`](../../backend/supabase/migrations/20260424002200_seed_inmuk_chaeyoung_bosals.sql) 시드와 동기화. 마이그레이션이 적용된 환경에서만 로그인 가능.

### 4. 실행

```bash
# iOS 시뮬레이터 (가장 빠름)
flutter run -d <simulator_id>

# Android 에뮬레이터
flutter run -d android

# Web (Chrome)
flutter run -d chrome
```

`flutter devices` 로 사용 가능 디바이스 확인.

### 5. 빌드

```bash
# iOS 릴리즈
flutter build ios --release

# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# Web
flutter build web
```

---

## 개발 메모

- **첫 진입 시 mock 데이터**: 시뮬레이터에서 빠르게 흐름 테스트하려면 `.env`에서 `DATA_SOURCE=mock`. Supabase 가입·계정 필요 없음.
- **Supabase 모드**: 시드된 데모 보살(`inmuk@bosal.test`, `chaeyoung@bosal.test`)로 보살 사장 흐름 검증 가능. 일반 사용자는 회원가입 화면(`/signup`)에서 새 계정 생성.
- **알림·예약 Realtime**: Supabase Realtime publication에 등록된 `notifications` / `reservations` 만 stream으로 자동 갱신. 다른 테이블은 polling 필요.
- **빈 상태 / 로딩 / 에러 가드**: 모든 AsyncValue 호출은 `.when(data:..., loading:..., error:...)` 또는 maybeWhen으로 보호. 새 화면 추가 시 동일 패턴 유지.

---

## 라이선스

비공개 / 내부 프로젝트.
