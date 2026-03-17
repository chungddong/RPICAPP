import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device.dart';
import '../providers/device_provider.dart';

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
                const Text('Arduino를 USB로 연결하세요', 
                  style: TextStyle(fontSize: 12)),
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
