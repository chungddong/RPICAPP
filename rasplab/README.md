# RaspLab Flutter App

> 라즈베리파이와 BLE로 통신하는 채팅 앱

## 📱 앱 특징

- 🎨 **깔끔한 UI**: Dark theme + 반응형 (폰/태블릿)
- 💬 **세션 저장**: SQLite로 채팅 기록 자동 저장  
- 🔌 **BLE 통신**: 최대 500바이트 청크 전송
- 📡 **실시간 결과**: Pi 코드 실행 결과 즉시 수신
- 🤖 **AI 통합**: Claude API로 자동 코드 생성

## 🛠 개발 환경

### 필수
- **Flutter 3.x** ([설치](https://flutter.dev/docs/get-started/install))
- **Android SDK** (API 30+)
- **ADB**

### 선택
- Android Studio (권장)
- VS Code + Flutter extension

## 🚀 빌드 & 실행

### 1️⃣ 설정

```bash
cd rasplab
flutter pub get
```

### 2️⃣ .env 파일

```bash
# 루트에 .env 생성
CLAUDE_API_KEY=sk-ant-api03-...
```

### 3️⃣ 빌드

**macOS/Linux:**
```bash
flutter run --release
```

**Windows (한글 경로 해결):**
```powershell
# 최초 1회
subst R: "d:\바탕화면\Develop\RPICAPP"

# 빌드
cd R:\rasplab
flutter run -d <device_id> --release
```

**기기 ID 확인:**
```bash
flutter devices
```

## 📁 폴더 구조

```
lib/
├── main.dart
├── config/
│   ├── theme.dart               # 다크테마
│   ├── constants.dart           # BLE UUID 상수
│   └── ...
├── models/
│   ├── message.dart             # 메시지
│   ├── chat_session.dart        # 세션 (DB 모델)
│   └── code_block.dart          # 코드블록
├── services/
│   ├── claude_service.dart      # Claude API
│   ├── ble_service.dart         # BLE 통신
│   ├── db_service.dart          # SQLite CRUD
│   └── ...
├── providers/                   # Riverpod
│   ├── chat_provider.dart       # 메시지 상태
│   ├── session_provider.dart    # 세션 상태
│   └── connection_provider.dart # BLE 상태
├── screens/
│   ├── home_screen.dart         # 메인 (드로어 + 챗)
│   ├── chat_screen.dart         # 채팅창
│   ├── connect_screen.dart      # BLE 연결
│   └── ...
└── widgets/
    ├── chat_bubble.dart
    ├── code_block_widget.dart   # 실행 버튼 포함
    ├── wiring_guide_card.dart   # 배선 가이드
    └── ...
```

## 🔧 핵심 구현

### Claude API 연동

```dart
// claude_service.dart
final response = await claudeService.sendMessage(messages);
// → Python 코드 자동 생성
```

### BLE 청크 전송

```dart
// ble_service.dart
await bleService.sendCode(pythonCode);
// → 500바이트씩 분할 + 답장 대기
```

### 세션 관리

```dart
// db_service.dart + session_provider.dart
// 메시지 자동 저장
// 세션 전환 시 자동 로드
```

## 📊 상태 흐름

```
chatMessagesProvider (Riverpod)
├─ sendUserMessage()    → DB 저장 + 리스트 갱신
├─ loadSession()        → 세션의 기존 메시지 로드
└─ clear()              → 새 세션 시 초기화

sessionProvider
├─ getAllSessions()     → 모든 세션 조회
├─ createSession()      → 새 세션 생성
├─ deleteSession()      → 세션 삭제
└─ updateSessionTitle() → 제목 변경
```

## 🎯 사용 플로우

```
1. HomeScreen (drawer + chat)
   ↓
2. BLE 기기 선택 (ConnectScreen)
   ↓
3. ChatScreen 진입
   ↓
4. 사용자: "LED 깜빡이게 해줘"
   ↓
5. Claude → Python 코드 생성
   ↓
6. ▶ 실행 버튼 터치
   ↓
7. BLE로 코드 전송 (청크 분할)
   ↓
8. Pi 실행 중...
   ↓
9. stdout 캡처 → BLE로 전송
   ↓
10. 결과 카드 표시
```

## 🎨 UI Highlights

### ChatScreen
- 메시지 목록 (자동 스크롤)
- 입력창 + 전송 버튼
- 로딩 애니메이션

### 말풍선 (ChatBubble)
- 텍스트 표시
- 배선 가이드 (green card)
- Python 코드블록 (syntax coloring)
- ▶ 실행 버튼

### 반응형
```
768px 이상: 태블릿 모드 (고정 사이드바 280px)
768px 미만: 폰 모드 (드로어)
```

## ⚙️ 설정 & 상수

**BLE UUID** ([config/constants.dart](lib/config/constants.dart)):
```dart
const String SERVICE_UUID = '0000fff0-0000-1000-8000-00805f9b34fb';
const String CODE_WRITE_UUID = '0000fff1-0000-1000-8000-00805f9b34fb';
const String RESULT_READ_UUID = '0000fff2-0000-1000-8000-00805f9b34fb';
const String CONTROL_UUID = '0000fff3-0000-1000-8000-00805f9b34fb';
```

**Claude API** ([services/claude_service.dart](lib/services/claude_service.dart)):
```dart
const String CLAUDE_MODEL = 'claude-haiku-4-5-20251001';
const String API_ENDPOINT = 'https://api.anthropic.com/v1/messages';
```

## 🐛 디버깅

**로그 출력**
```bash
flutter run
# 콘솔에 print() 메시지 표시
```

**분석**
```bash
flutter analyze

# 의존성 체크
flutter pub outdated
```

**상태 검사**
```dart
// Riverpod DevTools 추가 (향후)
// devtools로 상태 추적 가능
```

## 📦 의존성

[pubspec.yaml](pubspec.yaml) 참고:
- `flutter_riverpod` 2.6.1 — 상태관리
- `flutter_blue_plus` 1.35.3 — BLE
- `sqflite` — 로컬 DB
- `http` — Claude API

## 🔗 관련 링크

- [BLE 프로토콜 명세](../pi/SETUP.md)
- [Riverpod 공식](https://riverpod.dev)
- [Flutter 공식](https://flutter.dev)

