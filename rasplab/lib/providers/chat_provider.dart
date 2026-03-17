import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../models/device.dart';
import '../services/claude_service.dart';
import 'session_provider.dart';
import 'device_provider.dart';
import 'ble_provider.dart';

final claudeServiceProvider = Provider<ClaudeService>((ref) => ClaudeService());

final chatMessagesProvider =
    NotifierProvider<ChatNotifier, List<Message>>(ChatNotifier.new);

class ChatNotifier extends Notifier<List<Message>> {
  @override
  List<Message> build() => [];

  // 세션 전환: DB에서 메시지 로드
  Future<void> loadSession(String sessionId) async {
    state = [];
    final messages = await ref.read(dbServiceProvider).getMessages(sessionId);
    state = messages;
  }

  void clear() => state = [];

  // 기기 선택 처리
  Future<void> selectDevice(Device device) async {
    // 로컬 상태 업데이트
    ref.read(selectedDeviceProvider.notifier).state = device;

    // BLE를 통해 Pi에 기기 선택 메시지 전송
    try {
      final bleManager = ref.read(bleManagerProvider);
      await bleManager.selectDevice(device.id);
      print('Device ${device.name} selected via BLE');
    } catch (e) {
      print('Failed to select device: $e');
    }
  }

  // 사용자 메시지 전송 → Claude 응답 요청
  Future<void> sendUserMessage(String text) async {
    // 활성 세션 없으면 자동 생성
    String? sessionId = ref.read(activeSessionIdProvider);
    if (sessionId == null) {
      final session =
          await ref.read(sessionsProvider.notifier).createSession();
      sessionId = session.id;
      ref.read(activeSessionIdProvider.notifier).state = sessionId;
    }

    final userMsg = Message.user(text);
    state = [...state, userMsg];
    await ref.read(dbServiceProvider).insertMessage(sessionId, userMsg);

    // 첫 메시지로 세션 제목 자동 설정
    final userMsgCount = state.where((m) => m.isUser).length;
    if (userMsgCount == 1) {
      final title = text.length > 24 ? '${text.substring(0, 24)}…' : text;
      await ref
          .read(sessionsProvider.notifier)
          .renameSession(sessionId, title);
    }

    // 로딩 플레이스홀더
    final loadingId = 'loading_${DateTime.now().millisecondsSinceEpoch}';
    final loadingMsg = Message(
      id: loadingId,
      role: MessageRole.assistant,
      content: '...',
    );
    state = [...state, loadingMsg];

    try {
      final claude = ref.read(claudeServiceProvider);
      final history = state.sublist(0, state.length - 1);
      final selectedDevice = ref.read(selectedDeviceProvider);
      
      // 기기별 커스텀 AI 프롬프트 사용
      final systemPrompt = selectedDevice?.aiSystemPrompt;
      final response = await claude.sendMessage(
        history,
        systemPrompt: systemPrompt,
      );

      // Message.fromJson으로 codeBlocks 재파싱
      final parsed = Message.fromJson({
        'id': loadingId,
        'role': MessageRole.assistant.name,
        'content': response,
        'timestamp': loadingMsg.timestamp.millisecondsSinceEpoch,
      });

      state = [...state.sublist(0, state.length - 1), parsed];
      await ref.read(dbServiceProvider).insertMessage(sessionId, parsed);
      await ref.read(sessionsProvider.notifier).touchSession(sessionId);
    } catch (e) {
      final errMsg = Message(
        id: loadingId,
        role: MessageRole.assistant,
        content: '오류 발생: $e',
        timestamp: loadingMsg.timestamp,
      );
      state = [...state.sublist(0, state.length - 1), errMsg];
    }
  }
}