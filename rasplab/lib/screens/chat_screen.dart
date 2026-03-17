import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device.dart';
import '../providers/chat_provider.dart';
import '../providers/device_provider.dart';
import '../providers/ble_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/device_selector.dart';

/// ChatScreen은 HomeScreen의 body로 삽입됩니다 (Scaffold 없음).
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    await ref.read(chatMessagesProvider.notifier).sendUserMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDevice = ref.watch(selectedDeviceProvider);
    final messages = ref.watch(chatMessagesProvider);

    // 기기가 선택되지 않으면 선택 화면 표시
    if (selectedDevice == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('기기 선택')),
        body: DeviceSelector(
          onDeviceSelected: (device) {
            // ChatNotifier의 selectDevice 메서드를 호출 (BLE 메시지 전송 포함)
            ref.read(chatMessagesProvider.notifier).selectDevice(device);
          },
        ),
      );
    }

    // 새 메시지가 오면 자동 스크롤
    if (messages.isNotEmpty) _scrollToBottom();

    // 기기가 선택된 경우
    return Column(
      children: [
        // ── 선택된 기기 정보 ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selectedDevice.type == DeviceType.raspberryPi
                ? Colors.orange.shade100
                : Colors.blue.shade100,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [
              Icon(
                selectedDevice.type == DeviceType.raspberryPi
                    ? Icons.router
                    : Icons.memory,
                color: selectedDevice.type == DeviceType.raspberryPi
                    ? Colors.orange
                    : Colors.blue,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedDevice.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${selectedDevice.codeLanguage} • ${selectedDevice.boardType}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.read(selectedDeviceProvider.notifier).state = null;
                },
                child: const Text('변경'),
              ),
            ],
          ),
        ),

        // ── 채팅 메시지 목록 ──────────────────────────────────────────
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selectedDevice.type == DeviceType.raspberryPi
                              ? Icons.developer_board
                              : Icons.memory,
                          size: 56,
                          color: const Color(0xFF313244),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          selectedDevice.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6C7086),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          selectedDevice.type == DeviceType.raspberryPi
                              ? '"LED를 1초 간격으로 깜빡이게 해줘"\n"온도센서 값을 읽어서 출력해줘"'
                              : '"LED를 켜는 코드를 만들어줘"\n"Serial로 숫자를 출력하는 코드"',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6C7086),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  itemCount: messages.length,
                  itemBuilder: (_, i) => ChatBubble(message: messages[i]),
                ),
        ),

        // ── 입력창 ───────────────────────────────────────────────────
        SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E2E),
              border: Border(top: BorderSide(color: Color(0xFF313244))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    decoration: InputDecoration(
                      hintText: selectedDevice.type == DeviceType.raspberryPi
                          ? '라즈베리파이에게 물어보세요...'
                          : '${selectedDevice.name}에게 명령하세요...',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: 6,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  heroTag: 'send_btn',
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send, size: 20),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

