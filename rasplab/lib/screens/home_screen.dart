import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_session.dart';
import '../providers/chat_provider.dart';
import '../providers/session_provider.dart';
import '../widgets/connection_indicator.dart';
import 'chat_screen.dart';

// 태블릿 기준 너비 (dp)
const _kTabletBreakpoint = 600.0;
const _kSidebarWidth = 280.0;

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsProvider);
    final activeId = ref.watch(activeSessionIdProvider);
    final isTablet = MediaQuery.of(context).size.width >= _kTabletBreakpoint;

    if (isTablet) {
      // ── 태블릿: 고정 사이드바 + 채팅 영역 ───────────────────────────
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              const Icon(Icons.developer_board,
                  color: Color(0xFF82AAFF), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _sessionTitle(sessionsAsync.value, activeId),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 12),
              child: ConnectionIndicator(),
            ),
          ],
        ),
        body: Row(
          children: [
            // 사이드바 고정
            SizedBox(
              width: _kSidebarWidth,
              child: _buildSidebarContent(
                context, ref, sessionsAsync, activeId,
                isTablet: true,
              ),
            ),
            const VerticalDivider(
                width: 1, thickness: 1, color: Color(0xFF313244)),
            // 채팅 영역
            const Expanded(child: ChatScreen()),
          ],
        ),
      );
    }

    // ── 폰: 드로어 방식 ──────────────────────────────────────────────
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _sessionTitle(sessionsAsync.value, activeId),
          overflow: TextOverflow.ellipsis,
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: ConnectionIndicator(),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1E1E2E),
        child: _buildSidebarContent(
          context, ref, sessionsAsync, activeId,
          isTablet: false,
        ),
      ),
      body: const ChatScreen(),
    );
  }

  String _sessionTitle(List<ChatSession>? sessions, String? activeId) {
    if (activeId == null || sessions == null) return 'RaspLab';
    try {
      return sessions.firstWhere((s) => s.id == activeId).title;
    } catch (_) {
      return 'RaspLab';
    }
  }

  // ── 사이드바 콘텐츠 (드로어·태블릿 공용) ─────────────────────────────
  Widget _buildSidebarContent(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ChatSession>> sessionsAsync,
    String? activeId, {
    required bool isTablet,
  }) {
    return Container(
      color: const Color(0xFF1E1E2E),
      child: Column(
        children: [
          // ── 헤더 ──────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.developer_board,
                      color: Color(0xFF82AAFF), size: 22),
                  const SizedBox(width: 10),
                  const Text(
                    'RaspLab',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFCDD6F4),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 새 채팅 버튼 ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF313244),
                  foregroundColor: const Color(0xFFCDD6F4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () =>
                    _startNewChat(context, ref, isTablet: isTablet),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('새 채팅'),
              ),
            ),
          ),

          const Divider(color: Color(0xFF313244), height: 16),

          // ── 채팅 기록 목록 ─────────────────────────────────────────
          Expanded(
            child: sessionsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                  child: Text('오류: $e',
                      style: const TextStyle(color: Colors.red))),
              data: (sessions) => sessions.isEmpty
                  ? const Center(
                      child: Text(
                        '채팅 기록 없음',
                        style: TextStyle(color: Color(0xFF6C7086)),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: sessions.length,
                      itemBuilder: (_, i) => _SessionTile(
                        session: sessions[i],
                        isActive: sessions[i].id == activeId,
                        onTap: () => _openSession(
                            context, ref, sessions[i].id,
                            isTablet: isTablet),
                        onDelete: () => _deleteSession(
                            context, ref, sessions[i].id, activeId),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startNewChat(BuildContext context, WidgetRef ref,
      {required bool isTablet}) async {
    ref.read(activeSessionIdProvider.notifier).state = null;
    ref.read(chatMessagesProvider.notifier).clear();
    if (!isTablet && context.mounted) Navigator.pop(context); // 드로어 닫기
  }

  Future<void> _openSession(BuildContext context, WidgetRef ref, String sessionId,
      {required bool isTablet}) async {
    ref.read(activeSessionIdProvider.notifier).state = sessionId;
    await ref.read(chatMessagesProvider.notifier).loadSession(sessionId);
    if (!isTablet && context.mounted) Navigator.pop(context); // 드로어 닫기
  }

  Future<void> _deleteSession(
      BuildContext context, WidgetRef ref, String sessionId, String? activeId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF313244),
        title: const Text('채팅 삭제'),
        content: const Text('이 채팅을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('삭제', style: TextStyle(color: Color(0xFFF38BA8))),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(sessionsProvider.notifier).deleteSession(sessionId);
    if (activeId == sessionId) {
      ref.read(activeSessionIdProvider.notifier).state = null;
      ref.read(chatMessagesProvider.notifier).clear();
    }
  }
}

// ── 세션 타일 ── ─────────────────────────────────────────────────────────────
class _SessionTile extends StatelessWidget {
  final ChatSession session;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SessionTile({
    required this.session,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: isActive,
      selectedTileColor: const Color(0xFF313244),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(
        Icons.chat_bubble_outline,
        size: 18,
        color: isActive ? const Color(0xFF82AAFF) : const Color(0xFF6C7086),
      ),
      title: Text(
        session.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          color: isActive
              ? const Color(0xFFCDD6F4)
              : const Color(0xFF9399B2),
        ),
      ),
      subtitle: Text(
        _formatDate(session.updatedAt),
        style: const TextStyle(fontSize: 11, color: Color(0xFF6C7086)),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline,
            size: 16, color: Color(0xFF6C7086)),
        onPressed: onDelete,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
      onTap: onTap,
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${dt.month}/${dt.day}';
  }
}
