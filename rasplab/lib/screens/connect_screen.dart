import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/device.dart';
import '../providers/connection_provider.dart';
import '../services/qr_service.dart';
import '../config/theme.dart';
import '../widgets/device_list_tile.dart';
import '../widgets/connection_indicator.dart';

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<RaspDevice> _scannedDevices = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _startScan();
  }

  @override
  void dispose() {
    _tabController.dispose();
    ref.read(bleServiceProvider).stopScan();
    super.dispose();
  }

  void _startScan() {
    setState(() {
      _scannedDevices.clear();
      _isScanning = true;
    });
    try {
      ref.read(bleServiceProvider).scan().listen(
        (device) {
          if (!_scannedDevices.any((d) => d.macAddress == device.macAddress)) {
            setState(() => _scannedDevices.add(device));
          }
        },
        onDone: () => setState(() => _isScanning = false),
        onError: (e) {
          setState(() => _isScanning = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('블루투스를 켜주세요: $e'),
                backgroundColor: const Color(0xFFF38BA8),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
      );
    } catch (e) {
      setState(() => _isScanning = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('블루투스가 꺼져 있습니다. 블루투스를 켜고 다시 시도하세요.'),
            backgroundColor: const Color(0xFFF38BA8),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _connectToDevice(RaspDevice device) async {
    try {
      await ref.read(connectionProvider.notifier).connect(device);
      if (mounted) Navigator.of(context).pop(); // 연결 완료 → 이전 화면으로
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('연결 실패: $e'), backgroundColor: kErrorColor),
        );
      }
    }
  }

  void _onQrDetect(BarcodeCapture capture) {
    final raw = capture.barcodes.first.rawValue;
    if (raw == null) return;
    final mac = QrService.parseMacAddress(raw);
    if (mac == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('잘못된 QR 코드입니다.')),
      );
      return;
    }
    // MAC으로 기기 찾기 (스캔된 목록에서)
    final device = _scannedDevices.firstWhere(
      (d) => d.macAddress.toUpperCase() == mac,
      orElse: () => throw Exception('기기를 찾을 수 없습니다. BLE 탭에서 먼저 스캔하세요.'),
    );
    _connectToDevice(device);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('기기 연결'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.bluetooth_searching), text: '기기 검색'),
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'QR 스캔'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── BLE 스캔 탭 ─────────────────
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const ConnectionIndicator(),
                    ElevatedButton.icon(
                      onPressed: _isScanning ? null : _startScan,
                      icon: const Icon(Icons.refresh),
                      label: Text(_isScanning ? '검색 중...' : '다시 검색'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _scannedDevices.isEmpty
                    ? Center(
                        child: _isScanning
                            ? const CircularProgressIndicator()
                            : const Text('주변에 RaspLab 기기가 없습니다.'),
                      )
                    : ListView.builder(
                        itemCount: _scannedDevices.length,
                        itemBuilder: (_, i) => DeviceListTile(
                          device: _scannedDevices[i],
                          onTap: () => _connectToDevice(_scannedDevices[i]),
                        ),
                      ),
              ),
            ],
          ),

          // ── QR 스캔 탭 ─────────────────
          MobileScanner(
            onDetect: _onQrDetect,
          ),
        ],
      ),
    );
  }
}
