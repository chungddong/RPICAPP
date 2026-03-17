import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device.dart';
import '../config/constants.dart';
import '../services/ble_service.dart';
import 'connection_provider.dart';

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
      await _bleService.writeRawPacket(packet);
    } catch (e) {
      print('BLE send error: $e');
      rethrow;
    }
  }

  Future<String?> requestDeviceListRaw() async {
    await sendMessage(0x10, const []);

    final result = await _bleService.resultStream
        .firstWhere((r) {
          if (!r.success) return false;
          final output = r.output.trim();
          // 장치 목록 응답은 JSON 배열 형태
          return output.startsWith('[') && output.contains('"board_type"');
        })
        .timeout(
          const Duration(seconds: 8),
          onTimeout: () => const ExecutionResult(
            success: false,
            output: '',
            error: '장치 목록 요청 타임아웃',
          ),
        );

    if (!result.success) {
      throw Exception(result.error ?? '장치 목록 요청 실패');
    }

    _lastResponse = result.output;
    return _lastResponse;
  }

  /// 0x11: 기기 선택
  Future<void> selectDevice(String deviceId) async {
    final payload = deviceId.codeUnits;
    await sendMessage(0x11, payload);
  }

  /// 0x12: Arduino 코드 업로드 (기존 sendCode 재활용)
  Future<ExecutionResult> uploadArduinoCode(String code) async {
    if (_bleService.connectedDevice == null) {
      throw Exception('BLE 미연결');
    }

    final bytes = Uint8List.fromList(code.codeUnits);
    final chunks = _splitChunks(bytes, kBlePayloadSize);
    final total = chunks.length;

    for (int i = 0; i < total; i++) {
      final packet = _buildPacket(0x12, i + 1, total, chunks[i]);
      await _bleService.writeRawPacket(packet);
    }

    final result = await _bleService.resultStream.first.timeout(
      const Duration(seconds: 120),
      onTimeout: () => const ExecutionResult(
        success: false,
        output: '',
        error: 'Arduino 업로드 타임아웃 (120초 초과)',
      ),
    );

    return result;
  }

  List<Uint8List> _splitChunks(Uint8List data, int size) {
    final chunks = <Uint8List>[];
    for (int i = 0; i < data.length; i += size) {
      final end = (i + size).clamp(0, data.length);
      chunks.add(data.sublist(i, end));
    }
    if (chunks.isEmpty) chunks.add(Uint8List(0));
    return chunks;
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
