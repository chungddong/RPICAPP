import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_bubble.dart';

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
    final messages = ref.watch(chatMessagesProvider);

    // 새 메시지가 오면 자동 스크롤
    if (messages.isNotEmpty) _scrollToBottom();

    return Column(
      children: [
        // ── 채팅 메시지 목록 ──────────────────────────────────────────
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.developer_board,
                            size: 56, color: Color(0xFF313244)),
                        SizedBox(height: 16),
                        Text(
                          'RaspLab',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6C7086),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '"LED를 1초 간격으로 깜빡이게 해줘"\n"온도센서 값을 읽어서 출력해줘"',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF6C7086)),
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
                    decoration: const InputDecoration(
                      hintText: '라즈베리파이에게 물어보세요...',
                      contentPadding: EdgeInsets.symmetric(
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
