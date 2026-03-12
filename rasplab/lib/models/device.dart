import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum DeviceConnectionState { disconnected, connecting, connected, disconnecting }

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
