# 강남보살 — 베타/정식 출시 체크리스트

P6 단계의 외부 작업 항목. 사용자가 자료를 준비하고 명령을 실행하는 단계.

---

## 1. 앱 아이콘 / 스플래시 (P6-1)

### 자료 준비

- `apps/mobile/assets/launcher/icon-1024.png` — 1024×1024 PNG, **알파 채널 없음** (App Store 요구)
- `apps/mobile/assets/launcher/splash.png` — 1242×2436 권장, 중앙 배치 (큰 여백 OK)

### 적용

```bash
cd apps/mobile
mkdir -p assets/launcher
# 디자인팀에서 받은 final 이미지를 위 경로로 복사

dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

생성 결과는 ios/Runner/Assets.xcassets/AppIcon, android/app/src/main/res/mipmap-* 등에 자동 배치.

---

## 2. 앱 이름 / 빌드 번호

### iOS — `apps/mobile/ios/Runner/Info.plist`

이미 적용됨:
- `CFBundleDisplayName`: 강남보살
- `CFBundleLocalizations`: ko, en

빌드 시 자동:
- `CFBundleShortVersionString` ← `pubspec.yaml`의 `version: 1.0.0+1` 앞부분
- `CFBundleVersion` ← `+1` 뒤 빌드 번호

출시 직전 `pubspec.yaml`의 `version` 갱신.

### Android — `apps/mobile/android/app/build.gradle.kts`

확인:
- `applicationId` (예: `com.wadidu.gangnam_bosal`)
- `versionCode` / `versionName` ← Flutter가 자동 처리

출시 키스토어:
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
`apps/mobile/android/key.properties` 파일 생성 (gitignore됨):
```
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=/Users/<you>/upload-keystore.jks
```

---

## 3. App Store Connect 메타 (P6-2)

### 필수 입력

| 항목 | 예시·가이드 |
|---|---|
| 앱 이름 | 강남보살 |
| 부제 (30자) | 나에게 맞는 보살 찾기 |
| 설명 (4000자) | 지역·전문분야로 보살을 찾고 예약·후기까지 한 번에. … |
| 키워드 (100자) | 보살, 사주, 점, 운세, 강남, 신점, 타로, 상담, 예약 |
| 카테고리 | Lifestyle / Reference |
| 연령 등급 | 17+ (UGC + 운세 콘텐츠) |
| 지원 URL | https://wadidu.com/support (또는 임시) |
| 마케팅 URL | (선택) |
| 저작권 | © 2026 (주)와디두 |

### 스크린샷 (App Store)

- iPhone 6.9" (iPhone 17 Pro Max 등): 1320×2868, 5장
- iPhone 6.5" (iPhone 11 Pro Max 등): 1242×2688 또는 1284×2778, 5장
- (선택) iPad 13": 2064×2752, 5장

베타 빌드 → 시뮬레이터 캡처 (`xcrun simctl io booted screenshot ~/Desktop/shot.png`).

### 심사용 데모 계정

App Review Information에 다음 정보 입력:
- 일반 사용자: 신규 이메일 회원가입 안내 (또는 운영자가 사전 생성한 심사용 계정)
- 보살 사장: 운영자가 어드민 웹 초대 코드 흐름으로 사전 생성한 심사 전용 계정 1건. 이메일/비번은 `.env` 또는 비밀 메모로 관리하고 App Review 폼에만 입력 (코드/문서에는 박지 말 것).

### Export Compliance

- HTTPS 외 암호화 사용 X → 자체 분류 가능 (Standard encryption: HTTPS only)

---

## 4. Google Play Console 메타 (P6-2)

### 필수 입력

| 항목 | 가이드 |
|---|---|
| 앱 이름 | 강남보살 |
| 짧은 설명 (80자) | 지역 기반 보살 매칭 + 예약 + 후기 |
| 상세 설명 (4000자) | (App Store와 동일 본문 적당히 조정) |
| 카테고리 | 라이프스타일 |
| 콘텐츠 등급 설문 | UGC + 만남/연애 정보 → 청소년 이상 |

### 스크린샷

- 휴대전화: 1080×1920 ~ 1440×2960, 2~8장
- 7인치 태블릿: (선택)
- 10인치 태블릿: (선택)

### Privacy Policy URL

`https://wadidu.com/gangnam-bosal/privacy` 또는 임시. **앱 내 화면 (`/legal/privacy`)도 함께 제공해야 통과**.

---

## 5. Privacy Nutrition Label / Data Safety Form (P6-3)

### App Store Connect → App Privacy

수집 데이터 신고:

| 카테고리 | 항목 | 사용 목적 | 사용자 식별 연결 | 추적 |
|---|---|---|---|---|
| Contact Info | Email Address | App Functionality | Yes | No |
| Contact Info | Name (display_name) | App Functionality | Yes | No |
| Identifiers | User ID (auth.uid) | App Functionality | Yes | No |
| User Content | Photos (보살 프로필) | App Functionality | Yes | No |
| User Content | Other User Content (후기 본문) | App Functionality | Yes | No |
| Usage Data | Product Interaction (전화·예약·조회 이벤트) | Analytics | No (anonymized) | No |
| Diagnostics | Crash Data, Performance | Analytics | No | No |
| Location | Coarse Location (지역 선택 시) | App Functionality | Yes | No |

> 공급 후 App Tracking Transparency 별도 prompt 불필요 (광고 ID 미사용).

### Play Console → Data Safety

동일 항목으로 입력. "Data is collected" yes / "Encrypted in transit" yes (HTTPS) / "Users can request deletion" yes (회원 탈퇴 RPC).

---

## 6. 베타 배포 (P6-4)

### TestFlight (iOS)

```bash
cd apps/mobile
flutter build ipa --release
# Xcode → Window → Organizer → Distribute App → App Store Connect → Upload
```

또는 fastlane / Codemagic 자동화 (시나리오 C).

내부 테스터 추가:
- App Store Connect → TestFlight → Internal Testing → 사용자 초대

### Internal Testing (Android)

```bash
cd apps/mobile
flutter build appbundle --release
# Play Console → Internal testing → Create new release → Upload .aab
```

---

## 7. 어드민 웹 배포 (P3-9)

### Vercel

1. GitHub repo 연결 (`apps/admin_web/` 디렉토리 지정)
2. 환경변수:
   - `NEXT_PUBLIC_SUPABASE_URL` = (모바일과 동일)
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY` = (모바일과 동일)
3. **Password Protection 활성화** (Vercel Pro) — 미공개 URL이지만 추가 보호
4. 도메인: `admin-internal.gangnam-bosal.com` (DNS) 또는 `*.vercel.app`

### admin 계정 부트스트랩

1. `backend/supabase/.env.example` 을 `.env` 로 복사하고 `ADMIN_EMAIL` 채움 (.env 는 git ignore).
2. Supabase Dashboard → Auth → Users 에서 `ADMIN_EMAIL` 이메일로 신규 사용자 생성 (비번은 본인이 임의 설정).
3. `bash backend/supabase/scripts/print_bootstrap_admin_sql.sh` 실행해 SQL 출력 → SQL Editor 에 붙여넣고 실행.
4. 어드민 웹 로그인 시도.

---

## 8. 사전 점검 (Go/No-Go)

| 항목 | 확인 |
|---|---|
| `flutter analyze` 0 error | ☐ |
| 시뮬레이터·실기기에서 골든 패스 통과 | ☐ |
| 약관·개인정보 본문 final로 교체 | ☐ |
| 데모 admin 계정 비번 교체 (placeholder 미사용) | ☐ |
| `apps/mobile/.env`의 `SUPABASE_URL`이 prod 인스턴스 (시나리오 C에서 분리) | ☐ |
| 데모 보살 시드 (002200) prod 적용 여부 결정 (D6) | ☐ |
| 신고·탈퇴·약관 화면 모두 진입 가능 | ☐ |
| 어드민 웹에서 보살 등록 → 모바일에서 invite claim 흐름 검증 | ☐ |
| App Store Privacy Label 입력 | ☐ |
| TestFlight 첫 빌드 업로드 | ☐ |

---

## 9. 외부 사용자 작업 우선순위

1. **(D-2)** 앱 아이콘 final 1024×1024 받기 → P6-1 적용
2. **(D-2)** 약관·개인정보 본문 사내 작성 완료 → MD 파일 교체
3. **(D-1)** Apple Developer / Google Play Console 계정 결제 + Bundle ID 등록
4. **(D-1)** Supabase admin 계정 비밀번호 설정 + admin role 부여
5. **(D-Day)** 빌드 + 메타 입력 + 베타 배포
