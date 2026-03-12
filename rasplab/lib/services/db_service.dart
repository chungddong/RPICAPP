import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/chat_session.dart';
import '../models/message.dart';

class DbService {
  static Database? _db;

  Future<Database> get db async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dbPath = p.join(await getDatabasesPath(), 'rasplab.db');
    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE sessions (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE messages (
            id TEXT PRIMARY KEY,
            session_id TEXT NOT NULL,
            role TEXT NOT NULL,
            content TEXT NOT NULL,
            timestamp INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  // ── Sessions ──────────────────────────────────────────────────────────
  Future<List<ChatSession>> getAllSessions() async {
    final d = await db;
    final rows = await d.query('sessions', orderBy: 'updated_at DESC');
    return rows.map(ChatSession.fromMap).toList();
  }

  Future<void> insertSession(ChatSession s) async {
    final d = await db;
    await d.insert('sessions', s.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateSessionTitle(String id, String title) async {
    final d = await db;
    await d.update(
      'sessions',
      {'title': title, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> touchSession(String id) async {
    final d = await db;
    await d.update(
      'sessions',
      {'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteSession(String id) async {
    final d = await db;
    await d.delete('sessions', where: 'id = ?', whereArgs: [id]);
    await d.delete('messages', where: 'session_id = ?', whereArgs: [id]);
  }

  // ── Messages ──────────────────────────────────────────────────────────
  Future<List<Message>> getMessages(String sessionId) async {
    final d = await db;
    final rows = await d.query(
      'messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );
    return rows.map(Message.fromJson).toList();
  }

  Future<void> insertMessage(String sessionId, Message msg) async {
    final d = await db;
    final map = msg.toJson();
    map['session_id'] = sessionId;
    await d.insert('messages', map,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteMessages(String sessionId) async {
    final d = await db;
    await d.delete('messages', where: 'session_id = ?', whereArgs: [sessionId]);
  }
}
