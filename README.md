# RaspLab



## 기술 스택

| 영역 | 사용 기술 |
|------|-----------|
| 앱 프레임워크 | Flutter 3.x (Dart ^3.8.1) |
| 상태관리 | flutter_riverpod 2.6.1 |
| BLE 통신 | flutter_blue_plus 1.35.3 |
| 로컬 DB | sqflite (채팅 세션 기록) |
| AI API | Claude claude-haiku-4-5-20251001 |
| Pi BLE 서버 | Python + bless |
| Pi GPIO | gpiozero + lgpio (Pi 5 전용) |

---

## 프로젝트 구조

```
RPICAPP/
├── rasplab/          # Flutter 앱
│   ├── lib/
│   │   ├── main.dart
│   │   ├── config/       # 테마, 상수, BLE UUID
│   │   ├── models/       # Message, ChatSession, CodeBlock
│   │   ├── providers/    # chat, session, connection (Riverpod)
│   │   ├── screens/      # HomeScreen, ChatScreen, ConnectScreen
│   │   ├── services/     # claude_service, ble_service, db_service
│   │   └── widgets/      # ChatBubble, CodeBlockWidget, WiringGuideCard
│   └── pubspec.yaml
│
└── pi/               # 라즈베리파이 스크립트
    ├── raspi_ble_daemon.py   # BLE 데몬 (메인)
    ├── generate_qr.py        # QR 코드 생성
    ├── rasplab.service       # systemd 서비스 파일
    ├── requirements.txt
    └── SETUP.md              # Pi 상세 셋업 가이드
```

---

## 사전 준비

### 공통
- Raspberry Pi 4B 또는 5 (Bookworm OS 64-bit)
- Android 폰 / 태블릿 (Android 10 이상, BLE 지원)
- [Anthropic API 키](https://console.anthropic.com/)

### 개발 환경 (Windows)
- Flutter SDK 3.x
- Android SDK (Android Studio)
- ADB (기기 연결용)

> ⚠️ **한글 경로 주의**: 프로젝트 경로에 한글이 포함된 경우 Flutter 빌드가 실패할 수 있습니다.  
> 아래 [빌드 방법](#빌드--설치앱)의 `subst` 명령으로 우회하세요.

---

## 1. 앱 설치

### 1-1. 저장소 클론

```bash
git clone <repo_url>
cd RPICAPP
```

### 1-2. API 키 설정

`rasplab/.env` 파일 생성:

```
CLAUDE_API_KEY=sk-ant-api03-...
```

### 1-3. 의존성 설치

```powershell
cd rasplab
flutter pub get
```

### 1-4. 빌드 & 설치 (앱)

> Windows에서 한글 경로 우회가 필요한 경우:

```powershell
# 최초 1회만 (경로에 한글 있을 경우)
subst R: "d:\바탕화면\Develop\RPICAPP"

# 이후 빌드 시
cd R:\rasplab
flutter run -d <device_id> --release
```

연결된 기기 ID 확인:

```powershell
flutter devices
```

---

## 2. 라즈베리파이 셋업

> 자세한 내용은 [pi/SETUP.md](pi/SETUP.md) 참고

### 2-1. 파일 복사

```bash
sudo mkdir -p /opt/rasplab
# USB 또는 scp로 pi/ 폴더 내용을 /opt/rasplab/에 복사
sudo cp raspi_ble_daemon.py generate_qr.py rasplab.service /opt/rasplab/
```

### 2-2. 시스템 패키지 설치

```bash
sudo apt update
sudo apt install -y python3-pip python3-dbus bluez bluetooth libdbus-1-dev \
                   python3-gpiozero python3-lgpio
```

### 2-3. Python 가상환경 + bless 설치

```bash
sudo python3 -m venv /opt/rasplab/venv --system-site-packages
sudo /opt/rasplab/venv/bin/pip install bless
```

### 2-4. 테스트 실행

```bash
sudo /opt/rasplab/venv/bin/python3 /opt/rasplab/raspi_ble_daemon.py
```

정상 출력 예시:
```
[INFO] BLE 기기명: RaspLab-6A4B
[INFO] BLE 광고 시작: RaspLab-6A4B
[INFO] 앱 연결 대기 중...
```

### 2-5. systemd 자동 시작 등록

```bash
sudo cp /opt/rasplab/rasplab.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable rasplab
sudo systemctl start rasplab
```

이후 Pi 전원을 켤 때마다 BLE 데몬이 자동으로 시작됩니다.

---

## 3. 사용 방법

1. 라즈베리파이 전원 ON → BLE 데몬 자동 시작
2. 폰 앱 실행 → 우측 상단 BLE 배지 탭 → `RaspLab-XXXX` 선택 → 연결
3. 채팅창에서 원하는 동작을 자연어로 요청
   ```
   "LED를 1초 간격으로 깜빡이게 해줘"
   "온도 센서 값을 읽어서 출력해줘"
   ```
4. AI가 Python 코드를 생성 → 코드 블록의 **▶ 실행** 버튼 탭
5. Pi가 코드를 실행하고 결과를 앱에 반환

---

## BLE 프로토콜

```
Service UUID : 0000fff0-0000-1000-8000-00805f9b34fb

fff1 (Write)  : 폰 → Pi  코드 청크 전송
fff2 (Notify) : Pi → 폰  실행 결과 수신
fff3 (Write)  : 폰 → Pi  제어 명령 (중지 등)

패킷 구조: [TYPE 1B][SEQ 2B][TOTAL 2B][PAYLOAD 최대 507B]
  0x01 코드 청크 / 0x02 전송 완료(실행 시작)
  0x03 중지 요청 / 0x04 결과 청크
  0x05 실행 완료 / 0x06 에러
```

---

## 트러블슈팅

| 증상 | 해결 |
|------|------|
| Flutter 빌드 오류 (한글 경로) | `subst R: <경로>` 후 `R:\rasplab`에서 빌드 |
| BLE 기기 목록에 Pi 안 보임 | `sudo systemctl status rasplab` 확인, Pi와 2m 이내 거리 유지 |
| `RPi.GPIO` 임포트 오류 (Pi 5) | Claude가 자동으로 `gpiozero`로 코드 생성함. 새 채팅에서 재요청 |
| `bless` 설치 오류 | `sudo apt install python3-dev libdbus-glib-1-dev` 후 재시도 |
| 코드 실행 결과 안 옴 | 30초 타임아웃 확인, `sudo journalctl -u rasplab -f`로 Pi 로그 확인 |

---

## 라이선스

MIT
