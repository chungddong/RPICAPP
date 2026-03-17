import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../config/constants.dart';
import '../models/device.dart';

class BleService {
  BluetoothCharacteristic? _codeWriteChar;
  BluetoothCharacteristic? _resultReadChar;
  BluetoothCharacteristic? _controlChar;
  // _statusChar: 향후 상태 알림용 (현재 미사용)

  RaspDevice? _connectedDevice;
  RaspDevice? get connectedDevice => _connectedDevice;

  // 청크 재조립 버퍼
  final List<Uint8List> _resultChunks = [];
  final _resultController = StreamController<ExecutionResult>.broadcast();
  Stream<ExecutionResult> get resultStream => _resultController.stream;

  /// BLE 기기 스캔 (RaspLab- 접두사 필터)
  Stream<RaspDevice> scan({Duration timeout = const Duration(seconds: 10)}) {
    FlutterBluePlus.startScan(
      withNames: [], // 모두 스캔, 이름 필터는 아래에서 처리
      timeout: timeout,
    );

    return FlutterBluePlus.scanResults
        .expand((results) => results)
        .where((r) => r.device.platformName.startsWith(kDeviceNamePrefix))
        .map((r) => RaspDevice.fromBtDevice(r.device));
  }

  void stopScan() => FlutterBluePlus.stopScan();

  /// 기기 연결
  Future<void> connect(RaspDevice device) async {
    await device.btDevice.connect(autoConnect: false);
    await device.btDevice.requestMtu(512);

    final services = await device.btDevice.discoverServices();

    // UUID는 short(fff0) 또는 full(0000fff0-...) 형식 모두 허용
    bool _matchUuid(String discovered, String target) {
      final d = discovered.toLowerCase().replaceAll('-', '');
      final t = target.toLowerCase().replaceAll('-', '');
      return d == t || d.contains(t.substring(4, 8)); // short UUID 포함 여부
    }

    final bleService = services.firstWhere(
      (s) => _matchUuid(s.serviceUuid.toString(), kBleServiceUUID),
      orElse: () => throw Exception(
        '서비스를 찾을 수 없습니다.\n'
        '발견된 서비스: ${services.map((s) => s.serviceUuid.toString()).join(', ')}',
      ),
    );

    for (final char in bleService.characteristics) {
      final uuid = char.characteristicUuid.toString().toLowerCase().replaceAll('-', '');
      if (uuid.contains('fff1')) _codeWriteChar  = char;
      if (uuid.contains('fff2')) _resultReadChar = char;
      if (uuid.contains('fff3')) _controlChar    = char;
    }

    // Notify 구독
    await _resultReadChar?.setNotifyValue(true);
    _resultReadChar?.lastValueStream.listen(_onResultChunk);

    _connectedDevice = device
      ..connectionState = DeviceConnectionState.connected;
  }

  /// 코드 전송 후 실행 결과 대기
  Future<ExecutionResult> sendCode(String code) async {
    if (_codeWriteChar == null) throw Exception('BLE 미연결');

    final bytes = Uint8List.fromList(code.codeUnits);
    final chunks = _splitChunks(bytes, kBlePayloadSize);
    final total  = chunks.length;

    // 코드 청크 전송
    for (int i = 0; i < total; i++) {
      final packet = _buildPacket(kPacketTypeCodeChunk, i + 1, total, chunks[i]);
      await _codeWriteChar!.write(packet, withoutResponse: false);
    }

    // 실행 시작 신호
    final startPacket = _buildPacket(kPacketTypeCodeEnd, 0, 0, Uint8List(0));
    await _codeWriteChar!.write(startPacket, withoutResponse: false);

    _resultChunks.clear();

    // 결과 대기 (타임아웃 포함)
    return resultStream.first.timeout(
      Duration(seconds: kExecutionTimeoutSeconds),
      onTimeout: () => const ExecutionResult(
        success: false,
        output: '',
        error: '실행 타임아웃 (${kExecutionTimeoutSeconds}초 초과)',
      ),
    );
  }

  Future<void> writeRawPacket(Uint8List packet) async {
    if (_codeWriteChar == null) throw Exception('BLE 미연결');
    await _codeWriteChar!.write(packet, withoutResponse: false);
  }

  /// 실행 중지
  Future<void> stopExecution() async {
    if (_controlChar == null) return;
    final packet = _buildPacket(kPacketTypeStop, 0, 0, Uint8List(0));
    await _controlChar!.write(packet, withoutResponse: false);
  }

  /// 연결 해제
  Future<void> disconnect() async {
    await _connectedDevice?.btDevice.disconnect();
    _connectedDevice = null;
    _codeWriteChar = _resultReadChar = _controlChar = null;
  }

  // ── 내부 메서드 ─────────────────────────────────────────────

  void _onResultChunk(List<int> data) {
    if (data.isEmpty) return;
    final type = data[0];

    if (type == kPacketTypeResultChunk) {
      _resultChunks.add(Uint8List.fromList(data.sublist(5)));
    } else if (type == kPacketTypeResultEnd) {
      final combined = _combineChunks();
      _resultController.add(ExecutionResult(
        success: true,
        output: String.fromCharCodes(combined),
      ));
      _resultChunks.clear();
    } else if (type == kPacketTypeError) {
      final errMsg = String.fromCharCodes(data.sublist(5));
      _resultController.add(ExecutionResult(
        success: false,
        output: '',
        error: errMsg,
      ));
      _resultChunks.clear();
    }
  }

  Uint8List _combineChunks() {
    final total = _resultChunks.fold<int>(0, (s, c) => s + c.length);
    final result = Uint8List(total);
    int offset = 0;
    for (final chunk in _resultChunks) {
      result.setAll(offset, chunk);
      offset += chunk.length;
    }
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

  /// [TYPE(1)][SEQ(2)][TOTAL(2)][PAYLOAD]
  Uint8List _buildPacket(int type, int seq, int total, Uint8List payload) {
    final packet = Uint8List(5 + payload.length);
    packet[0] = type;
    packet[1] = (seq >> 8) & 0xFF;
    packet[2] = seq & 0xFF;
    packet[3] = (total >> 8) & 0xFF;
    packet[4] = total & 0xFF;
    packet.setAll(5, payload);
    return packet;
  }

  void dispose() {
    _resultController.close();
  }
}
