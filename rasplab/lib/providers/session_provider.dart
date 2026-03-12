import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_session.dart';
import '../services/db_service.dart';

final dbServiceProvider = Provider<DbService>((ref) => DbService());

// ── 세션 목록 ─────────────────────────────────────────────────────────────
final sessionsProvider =
    AsyncNotifierProvider<SessionsNotifier, List<ChatSession>>(
        SessionsNotifier.new);

class SessionsNotifier extends AsyncNotifier<List<ChatSession>> {
  @override
  Future<List<ChatSession>> build() =>
      ref.read(dbServiceProvider).getAllSessions();

  Future<ChatSession> createSession({String title = '새 채팅'}) async {
    final session = ChatSession.create(title: title);
    await ref.read(dbServiceProvider).insertSession(session);
    state = AsyncData([session, ...(state.value ?? [])]);
    return session;
  }

  Future<void> deleteSession(String id) async {
    await ref.read(dbServiceProvider).deleteSession(id);
    state = AsyncData((state.value ?? []).where((s) => s.id != id).toList());
  }

  Future<void> renameSession(String id, String title) async {
    await ref.read(dbServiceProvider).updateSessionTitle(id, title);
    state = AsyncData((state.value ?? []).map((s) {
      return s.id == id ? s.copyWith(title: title, updatedAt: DateTime.now()) : s;
    }).toList());
  }

  Future<void> touchSession(String id) async {
    await ref.read(dbServiceProvider).touchSession(id);
    final updated = (state.value ?? [])
        .map((s) => s.id == id ? s.copyWith(updatedAt: DateTime.now()) : s)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    state = AsyncData(updated);
  }
}

// ── 현재 활성 세션 ID ─────────────────────────────────────────────────────
final activeSessionIdProvider = StateProvider<String?>((ref) => null);
