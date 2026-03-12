import 'package:flutter/material.dart';
import '../models/device.dart';

class DeviceListTile extends StatelessWidget {
  final RaspDevice device;
  final VoidCallback onTap;

  const DeviceListTile({
    super.key,
    required this.device,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.bluetooth, color: Color(0xFF82AAFF)),
      title: Text(device.name),
      subtitle: Text(
        device.macAddress,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
