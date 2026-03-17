# RaspLab 🤖🍓

> 폰에서 AI(Claude)와 대화하면서 라즈베리파이 하드웨어를 제어하는 앱

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)](https://flutter.dev)
[![Python](https://img.shields.io/badge/Python-3.11%2B-green?logo=python)](https://www.python.org)
[![License](https://img.shields.io/badge/License-MIT-yellow)](#라이선스)

---

## 🎯 개요

```
[Claude API] ──HTTP──▶ [Flutter 앱] ──BLE──▶ [Raspberry Pi]
   코드 생성              두뇌 / UI             코드 실행기
```

**RaspLab**은 자연어 명령으로 라즈베리파이를 제어하는 풀스택 IoT 앱입니다.

- 🤖 **Claude AI**: 자연어 → Python 코드 생성
- 📱 **Flutter**: 채팅 UI + BLE 통신 + 세션 관리
- 🍓 **라즈베리파이**: BLE 데몬 + 코드 실행
- ⚡ **완전 자동화**: 한 줄 명령어로 Pi 셋업

---

## 🚀 빠른 시작

### 1️⃣ 앱 설치 (Android 폰)

```bash
git clone https://github.com/username/rasplab.git
cd rasplab/rasplab
flutter pub get
flutter run --release
```

### 2️⃣ Pi 설치 (한 줄)

```bash
curl -sSL https://raw.githubusercontent.com/username/rasplab/main/pi/setup.sh | sudo bash
```

### 3️⃣ 사용

1. Pi 전원 ON
2. 폰 앱 실행 → BLE 검색 → `RaspLab-XXXX` 연결
3. 채팅: *"LED를 1초 간격으로 깜빡이게 해줘"*
4. AI → 코드 생성 → ▶ 실행 → 결과 표시

**[더 자세한 가이드 →](/#-설치--사용--문서)**

---

## 📋 지원 기기

| 기기 | BLE | OS | 지원 |
|------|-----|-------|------|
| **Pi 4B** | ✅ | Bookworm | ✓ |
| **Pi 5** | ✅ | Bookworm | ✓ |
| **Pi Zero 2W** | ✅ | Bookworm | ✓ |
| **Android 10+** | ✅ | - | ✓ |

---

## 📁 폴더 구조

```
rasplab/
├── README.md                          # ← 지금 보는 문서
├── DEVELOPMENT.md                     # 개발 가이드
├── .gitignore
├── .env.example
│
├── rasplab/                           # 📱 Flutter 앱
│   ├── README.md                      # 앱 개발 가이드
│   ├── pubspec.yaml
│   └── lib/
│       ├── main.dart
│       ├── config/                    # 테마, 상수
│       ├── models/                    # 데이터 모델
│       ├── providers/                 # Riverpod 상태관리
│       ├── screens/                   # 화면
│       ├── services/                  # API, BLE, DB
│       └── widgets/                   # UI 컴포넌트
│
└── pi/                                # 🍓 라즈베리파이 스크립트
    ├── README.md                      # Pi 설치 가이드
    ├── setup.sh                       # 자동 설치 스크립트 ⭐
    ├── raspi_ble_daemon.py            # BLE 데몬
    ├── generate_qr.py                 # QR 코드 생성
    ├── rasplab.service                # systemd 서비스
    ├── requirements.txt
    └── SETUP.md                       # 수동 설치 상세 가이드
```

---

## 💻 기술 스택

| 영역 | 사용 기술 |
|------|-----------|
## 💻 기술 스택

### 앱 (Flutter)
| 라이브러리 | 용도 |
|-----------|------|
| **flutter_riverpod** | 상태관리 |
| **flutter_blue_plus** | BLE 통신 |
| **sqflite** | 로컬 DB |
| **http** | Claude API |

### 라즈베리파이
| 기술 | 용도 |
|------|------|
| **Python 3.11+** | 메인 언어 |
| **bless** | BLE Peripheral |
| **gpiozero** | GPIO 제어 |
| **lgpio** | Pi 5 GPU 백엔드 |

### AI
| 서비스 | 역할 |
|--------|------|
| **Claude Haiku** | 코드 생성 |
| **Anthropic API** | 엔드포인트 |

---

## 📖 설치 & 사용 & 문서

### 📱 앱 개발자 → [rasplab/README.md](rasplab/README.md)
- Flutter 빌드 방법 (Windows/Mac/Linux)
- 한글 경로 우회 (`subst` 명령)
- 앱 구조, 개발 팁

### 🍓 Pi 관리자 → [pi/README.md](pi/README.md)  
- **한 줄 자동 설치** (권장)
- systemd 관리 명령어
- 로그 확인 & 디버깅

### 📚 수동 설치 상세 → [pi/SETUP.md](pi/SETUP.md)
- 단계별 수동 설치
- 커스터마이징 옵션
- 트러블슈팅

### 👨‍💻 개발자용 → [DEVELOPMENT.md](DEVELOPMENT.md)
- 개발 환경 셋업
- 폴더 구조 상세
- PR 제출 가이드

---

## 💬 사용 예시

**사용자:**  
> "LED를 GPIO 17번에 연결했는데 1초 간격으로 깜빡이게 해줘"

**AI 응답:**
```python
import time
from gpiozero import LED

led = LED(17)  # GPIO 17번 핀

try:
    while True:
        led.on()
        time.sleep(0.5)
        led.off()
        time.sleep(0.5)
except KeyboardInterrupt:
    led.off()
    print("停止했습니다.")
```

**실행 결과:**
```
✅ 실행 성공
LED 깜빡임 시작
(0.5초 On + 0.5초 Off 반복)
```

---

## 🔌 BLE 통신 프로토콜

```
Service: 0000fff0-0000-1000-8000-00805f9b34fb

fff1 (Write):   폰 → Pi   코드 청크
fff2 (Notify):  Pi → 폰   실행 결과  
fff3 (Write):   폰 → Pi   제어 (중지 등)

[TYPE(1B)][SEQ(2B)][TOTAL(2B)][PAYLOAD(max 507B)]

0x01: 코드 청크 파트
0x02: 전송 완료 → 실행 시작
0x03: 중지 요청
0x04: 결과 청크 파트
0x05: 실행 완료
0x06: 에러 발생
```

---

## ⚡ 기능
