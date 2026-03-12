import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device.dart';
import '../services/ble_service.dart';

final bleServiceProvider = Provider<BleService>((ref) {
  final service = BleService();
  ref.onDispose(service.dispose);
  return service;
});

final connectionProvider =
    NotifierProvider<ConnectionNotifier, RaspDevice?>(ConnectionNotifier.new);

class ConnectionNotifier extends Notifier<RaspDevice?> {
  @override
  RaspDevice? build() => null;

  Future<void> connect(RaspDevice device) async {
    final ble = ref.read(bleServiceProvider);
    try {
      await ble.connect(device);
      state = device;
    } catch (e) {
      state = null;
      rethrow;
    }
  }

  Future<void> disconnect() async {
    final ble = ref.read(bleServiceProvider);
    await ble.disconnect();
    state = null;
  }

  bool get isConnected => state?.isConnected ?? false;
}
