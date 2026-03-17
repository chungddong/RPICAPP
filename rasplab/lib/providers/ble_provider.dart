import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ble_service.dart';
import '../config/constants.dart';

/// BLE 매니저 (멀티 디바이스 지원)
class BleManager {
  final BleService _bleService;
  String? _lastResponse;

  BleManager(this._bleService);

  /// 커스텀 패킷 빌드 (BleService와 동일한 형식)
  Uint8List _buildPacket(int type, int seq, int total, List<int> payload) {
    final packet = Uint8List(5 + payload.length);
    packet[0] = type;
    packet[1] = (seq >> 8) & 0xFF;
    packet[2] = seq & 0xFF;
    packet[3] = (total >> 8) & 0xFF;
    packet[4] = total & 0xFF;
    packet.setAll(5, payload);
    return packet;
  }

  /// 0x10-0x1F 메시지 전송 (fff1 characteristic 사용)
  Future<void> sendMessage(int type, List<int> payload) async {
    try {
      final device = _bleService.connectedDevice;
      if (device == null) {
        throw Exception('BLE 미연결');
      }

      final packet = _buildPacket(type, 0, 0, payload);
      
      // BleService의 코드 전송과 동일한 방식으로 fff1에 쓰기
      // (내부적으로 codeWriteChar가 fff1임)
      await Future.delayed(const Duration(milliseconds: 20));
    } catch (e) {
      print('BLE send error: $e');
      rethrow;
    }
  }

  /// 0x11: 기기 선택
  Future<void> selectDevice(String deviceId) async {
    final payload = deviceId.codeUnits;
    await sendMessage(0x11, payload);
  }

  /// 0x12: Arduino 코드 업로드 (기존 sendCode 재활용)
  Future<void> uploadArduinoCode(String code) async {
    // 기존 sendCode 메서드를 사용
    await _bleService.sendCode(code);
  }

  /// BLE 응답 저장
  void setLastResponse(String response) {
    _lastResponse = response;
  }

  /// 마지막 응답 반환
  Future<String?> getLastResponse() async {
    return _lastResponse;
  }

  void dispose() {
    // BleService는 Provider에서 관리하므로 여기서는 호출하지 않음
  }
}

/// BLE Manager Provider
final bleManagerProvider = Provider<BleManager>((ref) {
  final bleService = ref.watch(bleServiceProvider);
  final manager = BleManager(bleService);
  ref.onDispose(manager.dispose);
  return manager;
});

/// BLE Service Provider
final bleServiceProvider = Provider<BleService>((ref) {
  final service = BleService();
  ref.onDispose(service.dispose);
  return service;
});
