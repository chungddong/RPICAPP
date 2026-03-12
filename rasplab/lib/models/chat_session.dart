class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatSession.create({String title = '새 채팅'}) {
    final now = DateTime.now();
    return ChatSession(
      id: now.microsecondsSinceEpoch.toString(),
      title: title,
      createdAt: now,
      updatedAt: now,
    );
  }

  ChatSession copyWith({String? title, DateTime? updatedAt}) => ChatSession(
        id: id,
        title: title ?? this.title,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory ChatSession.fromMap(Map<String, dynamic> m) => ChatSession(
        id: m['id'] as String,
        title: m['title'] as String,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        updatedAt:
            DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
      );
}
