# 강남보살 (Gangnam Bosal)

> 나에게 맞는 보살을 찾아주는 모바일 플랫폼 MVP

Flutter 기반 크로스플랫폼 앱(iOS / Android / Web)으로, 사용자가 주변 보살을 검색·필터링하고 전화 상담을 연결할 수 있습니다.

---

## 기술 스택

| 영역 | 사용 기술 |
|---|---|
| 프레임워크 | Flutter (Dart `^3.7.0`) |
| 상태 관리 | `flutter_riverpod` |
| 라우팅 | `go_router` |
| 지도 | `flutter_map` + OpenStreetMap |
| 환경 변수 | `flutter_dotenv` |
| 기타 | `google_fonts`, `flutter_svg`, `url_launcher`, `intl` |

---

## 프로젝트 구조

```
lib/
├── main.dart            # 앱 엔트리포인트 (.env 로드)
├── app.dart             # MaterialApp 설정
├── core/                # 테마, 라우터, 공통 유틸
├── data/                # 모델, 목 데이터
├── features/            # 화면 단위 기능 (home, search, map, bosal, my …)
├── providers/           # Riverpod provider 모음
└── shared/              # 공용 위젯

assets/
├── images/              # 로고, 이미지
├── svg/                 # 아이콘
└── reference/           # 기획 참고 이미지

web/                     # Flutter Web 빌드 타깃 (favicon/icons 커스텀)
```

---

## 시작하기

### 1. 사전 요구사항

- Flutter SDK `^3.7.0`
- Xcode (iOS 빌드 시) / Android Studio (Android 빌드 시)
- Chrome 또는 Edge (Web 실행 시)

### 2. 의존성 설치

```bash
flutter pub get
```

### 3. 환경 변수 설정

`.env.example`을 복사해 `.env` 파일을 만들고 값을 채워 넣습니다.

```bash
cp .env.example .env
```

> `.env`는 `.gitignore`에 의해 커밋되지 않습니다. 새 환경 변수를 추가할 때는 **`.env.example`도 함께 업데이트**해주세요.

### 4. 실행

```bash
# Web
flutter run -d chrome

# iOS 시뮬레이터
flutter run -d ios

# Android 에뮬레이터
flutter run -d android
```

---

## 환경 변수 (`.env`)

| Key | 설명 |
|---|---|
| `TEST_USER_USERNAME` | MVP 데모용 일반 사용자 계정 ID |
| `TEST_USER_PASSWORD` | MVP 데모용 일반 사용자 계정 비밀번호 |
| `TEST_BOSAL_USERNAME` | MVP 데모용 보살 계정 ID |
| `TEST_BOSAL_PASSWORD` | MVP 데모용 보살 계정 비밀번호 |

> 현재는 MVP 단계로 목 데이터 기반입니다. 실제 API 연동 시 API 키·엔드포인트 등도 `.env`로 관리합니다.

---

## 빌드

```bash
# Web
flutter build web

# iOS (릴리스)
flutter build ios --release

# Android (APK)
flutter build apk --release

# Android (App Bundle)
flutter build appbundle --release
```

---

## 라이선스

비공개 / 내부 프로젝트.
