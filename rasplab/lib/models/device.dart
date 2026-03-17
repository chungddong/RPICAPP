import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum DeviceConnectionState { disconnected, connecting, connected, disconnecting }

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

class RaspDevice {
  final String name;
  final String macAddress;
  final BluetoothDevice btDevice;
  DeviceConnectionState connectionState;

  RaspDevice({
    required this.name,
    required this.macAddress,
    required this.btDevice,
    this.connectionState = DeviceConnectionState.disconnected,
  });

  bool get isConnected => connectionState == DeviceConnectionState.connected;

  factory RaspDevice.fromBtDevice(BluetoothDevice device) {
    return RaspDevice(
      name: device.platformName,
      macAddress: device.remoteId.str,
      btDevice: device,
    );
  }
}

class ExecutionResult {
  final bool success;
  final String output;
  final String? error;

  const ExecutionResult({
    required this.success,
    required this.output,
    this.error,
  });
}

// ─────────────────────────────────────────────────────────────
// 멀티 디바이스 모델
// ─────────────────────────────────────────────────────────────

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
