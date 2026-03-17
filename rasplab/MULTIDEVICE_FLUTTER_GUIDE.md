# 📱 Flutter 앱 - 멀티 디바이스 UI/UX 설계

## 🎯 변경 개요

| 화면 | 기존 | 신규 |
|------|------|------|
| **연결** | Pi BLE 스캔만 | Pi + 외부 기기 목록 |
| **선택** | 자동연결 | 기기별 선택 UI |
| **채팅** | Pi Python만 | 기기별 맞춤 AI (Python/Arduino) |
| **편집** | 종료 없음 | 기기별 언어 문법 강조 |

---

## 📁 신규 파일 구조

```
rasplab/lib/
├── models/
│   ├── device.dart              🆕 기기 데이터 모델
│   └── ... (기존)
│
├── providers/
│   ├── device_provider.dart     🆕 기기 목록 Riverpod
│   ├── ble_provider.dart        수정 (0x10 처리)
│   └── ... (기존)
│
├── widgets/
│   ├── device_selector.dart     🆕 기기 선택 UI
│   └── ... (기존)
│
├── screens/
│   ├── home_screen.dart         수정 (기기 선택 추가)
│   ├── chat_screen.dart         수정 (기기별 AI 프롬프트)
│   └── ... (기존)
│
└── ... (기존)
```

---

## 🧬 Step 1: 데이터 모델

### [lib/models/device.dart] 신규 생성

```dart
import 'package:flutter/foundation.dart';

enum DeviceType {
  raspberryPi,      // Pi 본체
  arduino,          // Arduino UNO/Nano
  esp32,           // ESP32
  stm32,           // STM32 등
}

enum DeviceStatus {
  disconnected,
  scanning,
  connected,
  uploading,
}

class Device {
  final String id;                    // 'pi' 또는 'device_abc123'
  final String name;                  // 'RaspLab Board', 'Arduino Uno #1'
  final DeviceType type;
  final String boardType;              // 'raspberry_pi_zero_2w', 'arduino:avr:uno'
  final String? port;                 // '/dev/ttyUSB0' (외부 기기만)
  final String? serialNumber;
  final DeviceStatus status;
  final DateTime connectedAt;

  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.boardType,
    this.port,
    this.serialNumber,
    this.status = DeviceStatus.disconnected,
    DateTime? connectedAt,
  }) : connectedAt = connectedAt ?? DateTime.now();

  /// AI 프롬프트 언어 결정
  String get codeLanguage {
    switch (type) {
      case DeviceType.raspberryPi:
        return 'Python';
      case DeviceType.arduino:
      case DeviceType.esp32:
      case DeviceType.stm32:
        return 'C++';
    }
  }

  /// 편집기 문법 강조 언어
  String get editorLanguage {
    switch (type) {
      case DeviceType.raspberryPi:
        return 'python';
      case DeviceType.arduino:
      case DeviceType.esp32:
      case DeviceType.stm32:
        return 'cpp';
    }
  }

  /// 기본 코드 템플릿
  String get defaultCodeTemplate {
    switch (type) {
      case DeviceType.raspberryPi:
        return '''# Raspberry Pi Python
print("Hello from RaspLab!")
# GPIO, sensor 제어 가능
''';
      case DeviceType.arduino:
        return '''#include <Arduino.h>

void setup() {
  Serial.begin(9600);
  pinMode(13, OUTPUT);
}

void loop() {
  digitalWrite(13, HIGH);
  delay(1000);
  digitalWrite(13, LOW);
  delay(1000);
}
''';
      case DeviceType.esp32:
        return '''#include <Arduino.h>

void setup() {
  Serial.begin(115200);
  Serial.println("ESP32 Ready");
}

void loop() {
  delay(1000);
}
''';
      case DeviceType.stm32:
        return '''// STM32 코드 작성
void setup() {
  // 초기화
}

void loop() {
  // 메인 루프
}
''';
    }
  }

  /// AI 시스템 프롬프트
  String get aiSystemPrompt {
    switch (type) {
      case DeviceType.raspberryPi:
        return '''당신은 Raspberry Pi 제어 전문가입니다.
사용자가 요청한 기능을 Python 3.11+ 코드로 구현하세요.
- GPIO: gpiozero 라이브러리 사용
- Sensors: 필요한 라이브러리(RPi.GPIO, Adafruit 등) 추천
- Serial: pyserial 사용
- 항상 간결하고 테스트된 코드 제공''';

      case DeviceType.arduino:
        return '''당신은 Arduino UNO 프로그래밍 전문가입니다.
사용자가 요청한 기능을 Arduino C++ 코드로 구현하세요.
- 보드: Arduino UNO R3 (ATmega328P)
- EEPROM, PWM, Interrupt 활용 가능
- 시리얼 통신: 9600 baud
- setup()과 loop() 필수 함수 포함
- 간결하고 메모리 효율적인 코드 작성''';

      case DeviceType.esp32:
        return '''당신은 ESP32 개발 전문가입니다.
사용자가 요청한 기능을 ESP32 C++ 코드로 구현하세요.
- 보드: ESP32-DevKit-V1
- Wi-Fi, BLE, I2C, SPI, ADC 활용 가능
- FreeRTOS 멀티태스킹 지원
- Serial: 115200 baud
- Async/Non-blocking 설계 권장''';

      case DeviceType.stm32:
        return '''당신은 STM32 마이크로컨트롤러 전문가입니다.
사용자가 요청한 기능을 STM32 C++ 코드로 구현하세요.
- HAL 또는 CMSIS 라이브러리 사용
- 고성능 ARM Cortex-M 아키텍처
- DMA, Timer, PWM 등 고급 기능 활용''';
    }
  }

  /// 업로드 프로세스 설명
  String get uploadHelpText {
    switch (type) {
      case DeviceType.raspberryPi:
        return '✓ 코드가 Pi에 전송되어 즉시 실행됩니다.\n출력은 아래에 표시됩니다.';
      case DeviceType.arduino:
        return '✓ 코드가 컴파일되고 펌웨어로 업로드됩니다.\n업로드 중... (약 5-10초)';
      case DeviceType.esp32:
        return '✓ 코드가 컴파일되고 보드로 플래시됩니다.\n업로드 중... (약 10-15초)';
      case DeviceType.stm32:
        return '✓ 코드가 컴파일되고 메모리에 쓰여집니다.\n업로드 중... (약 15-20초)';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Device &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  Device copyWith({
    String? id,
    String? name,
    DeviceType? type,
    String? boardType,
    String? port,
    String? serialNumber,
    DeviceStatus? status,
    DateTime? connectedAt,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      boardType: boardType ?? this.boardType,
      port: port ?? this.port,
      serialNumber: serialNumber ?? this.serialNumber,
      status: status ?? this.status,
      connectedAt: connectedAt ?? this.connectedAt,
    );
  }
}
```

---

## 🎨 Step 2: 기기 선택 UI

### [lib/widgets/device_selector.dart] 신규 생성

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device.dart';

class DeviceSelector extends ConsumerWidget {
  final Function(Device) onDeviceSelected;

  const DeviceSelector({
    Key? key,
    required this.onDeviceSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceList = ref.watch(deviceListProvider);

    return deviceList.when(
      loading: () => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('기기 검색 중...'),
          ],
        ),
      ),
      error: (err, st) => Center(
        child: Text('오류: $err'),
      ),
      data: (devices) {
        if (devices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('연결된 기기가 없습니다'),
                const SizedBox(height: 8),
                const Text('Arduino를 USB로 연결하세요', style: TextStyle(fontSize: 12)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: devices.length,
          itemBuilder: (context, index) {
            final device = devices[index];
            return DeviceCard(
              device: device,
              onTap: () => onDeviceSelected(device),
            );
          },
        );
      },
    );
  }
}

class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback onTap;

  const DeviceCard({
    Key? key,
    required this.device,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final icon = device.type == DeviceType.raspberryPi
        ? Icons.router
        : Icons.memory;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(device.name),
        subtitle: Text(
          '${device.boardType}${device.port != null ? ' • ${device.port}' : ''}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Chip(
          label: Text(device.codeLanguage),
          backgroundColor: device.type == DeviceType.raspberryPi
              ? Colors.orange.shade100
              : Colors.blue.shade100,
        ),
        onTap: onTap,
      ),
    );
  }
}
```

---

## 🔗 Step 3: Riverpod 상태 관리

### [lib/providers/device_provider.dart] 신규 생성

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/device.dart';
import 'ble_provider.dart';
import 'dart:convert';

/// 기기 목록 (BLE로부터 주기적 동기화)
final deviceListProvider = StreamProvider<List<Device>>((ref) async* {
  final bleManager = ref.watch(bleManagerProvider);

  while (true) {
    try {
      // 0x10: 장치 목록 요청
      await bleManager.sendMessage(0x10, []);
      
      // BLE에서 응답 대기
      final responseStream = ref.watch(bleResponseProvider);
      await for (final response in responseStream) {
        if (response.type == 0x04) {  // 결과 청크
          final devices = _parseDeviceList(response.payload);
          yield devices;
          break;
        }
      }

      // 5초마다 갱신
      await Future.delayed(const Duration(seconds: 5));
    } catch (e) {
      print('Device list error: $e');
      yield [];
    }
  }
});

/// 현재 선택 기기
final selectedDeviceProvider = StateProvider<Device?>((ref) => null);

/// 업로드 진행상황
final uploadProgressProvider = StateProvider<String?>((ref) => null);

// ────────────────────────────────────

List<Device> _parseDeviceList(String jsonString) {
  try {
    final json = jsonDecode(jsonString) as List;
    return json.map((item) {
      final type = item['type'] == 'platform' 
          ? DeviceType.raspberryPi 
          : DeviceType.arduino;  // 향후 esp32/stm32 추가
      
      return Device(
        id: item['id'],
        name: item['name'],
        type: type,
        boardType: item['board_type'] ?? 'unknown',
        port: item['port'],
        serialNumber: item['serial_number'],
      );
    }).toList();
  } catch (e) {
    print('Parse error: $e');
    return [];
  }
}
```

---

## 💬 Step 4: BLE 메시지 확장

### [lib/providers/ble_provider.dart] 수정

**기존:**
```dart
// 0x01-0x06만 지원
```

**신규 추가:**
```dart
// 0x10-0x1F 외부 장치 제어

class BleManager {
  // ...
  
  /// 0x11: 기기 선택
  Future<void> selectDevice(String deviceId) async {
    final payload = deviceId.codeUnits;
    await sendMessage(0x11, payload);
  }

  /// 0x12: Arduino 코드 업로드
  Future<void> uploadArduinoCode(String code) async {
    final codeBytes = utf8.encode(code);
    final chunks = _splitChunks(codeBytes);
    
    for (int i = 0; i < chunks.length; i++) {
      final payload = chunks[i];
      await sendMessage(0x12, payload, seq: i + 1, total: chunks.length);
      await Future.delayed(const Duration(milliseconds: 20));
    }
  }
}
```

---

## 🎭 Step 5: 채팅 화면 수정

### [lib/screens/chat_screen.dart] 수정

**변경 전:**
```dart
// Pi Python 코드만 처리
```

**변경 후:**
```dart
class ChatScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDevice = ref.watch(selectedDeviceProvider);

    if (selectedDevice == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('기기 선택')),
        body: DeviceSelector(
          onDeviceSelected: (device) {
            // 0x11: 기기 선택 명령 전송
            final ble = ref.read(bleManagerProvider);
            ble.selectDevice(device.id);
            ref.read(selectedDeviceProvider.notifier).state = device;
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(selectedDevice.type == DeviceType.raspberryPi 
                ? Icons.router 
                : Icons.memory),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(selectedDevice.name),
                Text(
                  selectedDevice.codeLanguage,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(selectedDeviceProvider.notifier).state = null;
            },
            child: const Text('변경'),
          ),
        ],
      ),
      body: ChatUI(
        device: selectedDevice,
        // AI 프롬프트: selectedDevice.aiSystemPrompt 사용
        // 코드 템플릿: selectedDevice.defaultCodeTemplate
      ),
    );
  }
}
```

---

## ⚙️ 구현 순서 (권장)

```
Week 1:
  ☐ lib/models/device.dart 작성
  ☐ lib/widgets/device_selector.dart 작성
  ☐ lib/providers/device_provider.dart 작성

Week 2:
  ☐ lib/providers/ble_provider.dart 0x10-0x1F 추가
  ☐ lib/screens/chat_screen.dart 수정
  ☐ AI 프롬프트 통합

Week 3:
  ☐ 코드 에디터 문법 강조 (python/cpp)
  ☐ Arduino 업로드 진행상황 표시
  ☐ 에러 핸들링

Week 4:
  ☐ UI/UX 다듬기
  ☐ 테스트 (Pi + Arduino)
```

---

## 🧪 테스트 체크리스트

- [ ] Pi 연결 후 기기 목록 표시
- [ ] Arduino (USB) 자동 감지
- [ ] 기기 선택 후 AI 프롬프트 변경
- [ ] Python 코드 실행 (Pi)
- [ ] Arduino C++ 컴파일 & 업로드
- [ ] 에러 핸들링 (USB 제거 시 자동 감지)

---

## 🚀 최종 사용 시나리오

```
1. 앱 실행 → 기기 목록 표시
   ✓ Raspberry Pi 본체
   ✓ Arduino Uno #1 (/dev/ttyUSB0)

2. "Arduino Uno #1" 선택
   → AI: "Arduino 제어 전문가"
   → 에디터: C++ 문법 강조
   → 템플릿: Blink 예제

3. LED 깜빡이는 코드 요청
   사용자: "LED를 3초마다 깜빡여"
   AI: (Arduino C++ 코드 생성)

4. [업로드] 클릭
   → BLE 0x12 메시지 전송
   → Pi: platformio compile & upload
   → 진행상황: [1/3] Compiling... [2/3] Uploading... [3/3] Done!
   → Arduino: 즉시 LED 깜빡임

5. 다시 Pi 선택
   → AI: "Python 제어 전문가"
   → 온습도 센서: gpiozero 코드로 전환
```

---

**이제 준비 완료! Flutter 구현을 시작하면 됩니다. 😊**
