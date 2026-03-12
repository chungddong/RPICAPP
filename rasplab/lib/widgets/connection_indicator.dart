import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connection_provider.dart';
import '../screens/connect_screen.dart';

class ConnectionIndicator extends ConsumerWidget {
  const ConnectionIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(connectionProvider);
    final isConnected = device?.isConnected ?? false;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ConnectScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isConnected
              ? const Color(0xFF1E3A1E)
              : const Color(0xFF2A2A3A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              size: 14,
              color: isConnected
                  ? const Color(0xFFA6E3A1)
                  : const Color(0xFF6C7086),
            ),
            const SizedBox(width: 5),
            Text(
              isConnected ? (device?.name ?? '연결됨') : '미연결',
              style: TextStyle(
                fontSize: 12,
                color: isConnected
                    ? const Color(0xFFA6E3A1)
                    : const Color(0xFF6C7086),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
