import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../models/device.dart';
import 'ble_provider.dart';
import 'connection_provider.dart';

/// 기기 목록 (Pi 본체 + USB 외부 기기)
final deviceListProvider = StreamProvider<List<Device>>((ref) async* {
  final connection = ref.watch(connectionProvider);

  // Pi가 연결되지 않으면 기본값 반환
  if (connection == null || !connection.isConnected) {
    yield [
      Device(
        id: 'pi',
        name: 'RaspLab Board',
        type: DeviceType.raspberryPi,
        boardType: 'raspberry_pi_zero_2w',
        status: DeviceStatus.disconnected,
      )
    ];
    return;
  }

  // Pi 본체는 항상 포함
  final devices = [
    Device(
      id: 'pi',
      name: 'RaspLab Board',
      type: DeviceType.raspberryPi,
      boardType: 'raspberry_pi_zero_2w',
      status: DeviceStatus.connected,
    )
  ];

  // 주기적으로 외부 기기 목록 요청
  while (true) {
    try {
      final bleManager = ref.read(bleManagerProvider);
      final response = await bleManager.requestDeviceListRaw();

      if (response != null && response.trim().isNotEmpty) {
        final parsed = _parseDeviceList(response);
        final merged = <Device>[
          devices.first,
          ...parsed.where((d) => d.id != 'pi'),
        ];
        yield merged;
      } else {
        yield devices;
      }
      
      // 5초마다 갱신
      await Future.delayed(const Duration(seconds: 5));
    } catch (e) {
      print('Device list error: $e');
      yield devices;
    }
  }
});

/// 현재 선택 기기
final selectedDeviceProvider = StateProvider<Device?>((ref) => null);

/// 업로드 진행상황
final uploadProgressProvider = StateProvider<String?>((ref) => null);

// ────────────────────────────────────────────────────────────────

List<Device> _parseDeviceList(String jsonString) {
  try {
    final json = jsonDecode(jsonString) as List;
    return json.map((item) {
      final typeStr = item['type'] as String? ?? 'platform';
      DeviceType type = DeviceType.raspberryPi;

      if (typeStr == 'external') {
        final boardType = item['board_type'] as String? ?? 'unknown';
        if (boardType.contains('arduino')) {
          type = DeviceType.arduino;
        } else if (boardType.contains('esp32')) {
          type = DeviceType.esp32;
        } else if (boardType.contains('stm32')) {
          type = DeviceType.stm32;
        }
      }

      return Device(
        id: item['id'],
        name: item['name'],
        type: type,
        boardType: item['board_type'] ?? 'unknown',
        port: item['port'],
        serialNumber: item['serial_number'],
        status: DeviceStatus.connected,
      );
    }).toList();
  } catch (e) {
    print('Parse device list error: $e');
    return [
      Device(
        id: 'pi',
        name: 'RaspLab Board',
        type: DeviceType.raspberryPi,
        boardType: 'raspberry_pi_zero_2w',
        status: DeviceStatus.connected,
      )
    ];
  }
}
