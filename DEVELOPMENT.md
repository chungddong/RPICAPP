# DEVELOPMENT 개발 가이드

개발자용 설정 및 기여 방법

## 🛠 개발 환경 셋업

### 1. 저장소 클론

```bash
git clone https://github.com/username/rasplab.git
cd rasplab
```

### 2. 분기 설정 (선택)

```bash
# 기능 개발용 분기
git checkout -b feature/your-feature
```

## 📱 Flutter 앱 개발

### 환경 설정

```bash
cd rasplab
flutter pub get
```

### 빌드 & 실행

```bash
# 디버그 모드 (빠른 개발)
flutter run

# 릴리즈 빌드 (최적화)
flutter run --release
```

### 코드 스타일

```bash
# 자동 포맷
dart format lib/ test/

# 분석 (오류/경고 확인)
flutter analyze
```

### 상태관리 (Riverpod)

새로운 상태 추가:

```dart
// providers/example_provider.dart
final exampleProvider = StateProvider<String>((ref) {
  return 'initial';
});

// 사용
final value = ref.watch(exampleProvider);
```

### 데이터베이스 (SQLite)

테이블 추가:

```dart
// services/db_service.dart
Future<void> _createTables(Database db) async {
  await db.execute('''
    CREATE TABLE new_table (...)
  ''');
}
```

### BLE 통신

코드 테스트:

```dart
// services/ble_service.dart
// 청크 분할 로직 테스트
final chunks = _splitCode(longPythonCode);
expect(chunks.length, greaterThan(1));
```

## 🍓 라즈베리파이 스크립트 개발

### 환경 설정

```bash
cd pi

# 가상환경 (개발용)
python3 -m venv venv
source venv/bin/activate

# 의존성
pip install -r requirements.txt
```

### 로컬 테스트

```bash
# Pi 없이 BLE 데몬 테스트 (에뮬레이션)
python3 raspi_ble_daemon.py --mock

# Pi에서 직접 테스트
sudo python3 raspi_ble_daemon.py
```

### 로깅

로그 추가:

```python
import logging

logging.info(f"메시지: {value}")
logging.error(f"에러 발생: {e}")
```

## 🧪 테스트

### Flutter 유닛 테스트

```bash
cd rasplab
flutter test
```

테스트 작성:

```dart
// test/services/ble_service_test.dart
void main() {
  test('코드 청크 분할', () {
    final code = '...' * 1000;  // 긴 코드
    final chunks = ble.splitCode(code);
    expect(chunks.length, greaterThan(1));
  });
}
```

### Python 단위 테스트

```bash
cd pi
python3 -m pytest tests/

# 또는 수동
python3 -m unittest tests.test_daemon
```

## 📖 문서화

### README 작성

- 마크다운 사용
- 코드 예시 포함
- 스크린샷 추가 (선택)

### 코드 주석

```dart
/// 이 함수는 BLE 코드를 청크로 분할합니다.
/// 
/// [code]: 전송할 Python 코드
/// [maxSize]: 청크 최대 크기 (기본 507)
/// 반환: 분할된 청크 리스트
List<List<int>> splitCode(String code, {int maxSize = 507}) {
  // ...
}
```

## 🔄 PR (Pull Request) 절차

### 1. 커밋

```bash
git add .
git commit -m "fix: BLE 청크 분할 오류 해결"
```

커밋 메시지 형식:
- `feat: 새 기능`
- `fix: 버그 수정`
- `docs: 문서`
- `refactor: 코드 정리`
- `test: 테스트 추가`

### 2. PR 생성

```bash
git push origin feature/your-feature
# GitHub에서 PR 생성
```

PR 체크리스트:
- [ ] 테스트 통과
- [ ] 코드 스타일 준수
- [ ] 문서 업데이트
- [ ] 한 가지 기능만 포함

### 3. Review & Merge

- 리뷰 피드백 처리
- 최소 1명 승인 후 merge

## 📊 프로젝트 구조

```
rasplab/
├── 📱 rasplab/          # Flutter 앱
│   ├── lib/
│   │   ├── config/      # 설정
│   │   ├── models/      # 데이터 모델
│   │   ├── providers/   # 상태관리
│   │   ├── screens/     # 화면
│   │   ├── services/    # API/BLE/DB
│   │   └── widgets/     # UI
│   └── test/            # 유닛 테스트
│
├── 🍓 pi/               # 라즈베리파이
│   ├── raspi_ble_daemon.py
│   ├── generate_qr.py
│   ├── setup.sh         # 자동 설치
│   ├── requirements.txt
│   ├── rasplab.service
│   ├── SETUP.md         # 수동 설치
│   └── README.md        # Pi 가이드
│
├── 📄 README.md         # 메인 문서
├── DEVELOPMENT.md       # 이 파일
├── .gitignore
├── .env.example
└── plan.md              # 기획
```

## 🚀 배포

### 앱 배포

```bash
cd rasplab

# Play Store (Android)
flutter build appbundle -v

# 서명 설정 필요 (key.properties)
```

### Pi 배포

```bash
# setup.sh가 자동으로 처리
# 사용자는 한 줄만 실행하면 됨
curl -sSL ... | sudo bash
```

## 🐛 디버깅 팁

### Flutter 디버깅

```bash
# 디버그 콘솔 활성화
flutter run
# 'h' = 도움말
# 'w' = 위젯 트리
# 'p' = 성능 측정
```

### BLE 문제

```bash
# Android nRF Connect 앱에서 UI 테스트
# 실제 BLE 특성 읽기/쓰기 확인
```

### Pi 문제

```bash
# 로그 확인
sudo journalctl -u rasplab -f

# 프로세스 직접 실행
sudo python3 /opt/rasplab/raspi_ble_daemon.py
```

## 📋 체크리스트

새 기능 추가 시:

- [ ] 로컬에서 테스트 완료
- [ ] 관련 문서 업데이트
- [ ] 색상/아이콘 일관성 유지
- [ ] BLE 프로토콜 명확히 문서화
- [ ] `flutter analyze` 오류 없음
- [ ] 한글 경로 호환성 확인

## 📞 지원

- **버그 리포트**: [Issues](https://github.com/username/rasplab/issues)
- **토론**: [Discussions](https://github.com/username/rasplab/discussions)
- **이메일**: (설정하면 추가)

---

Happy coding! 🚀
