import 'code_block.dart';

enum MessageRole { user, assistant, system }

class Message {
  final String id;
  final MessageRole role;
  final String content;
  final List<CodeBlock> codeBlocks;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.role,
    required this.content,
    List<CodeBlock>? codeBlocks,
    DateTime? timestamp,
  })  : codeBlocks = codeBlocks ?? [],
        timestamp = timestamp ?? DateTime.now();

  factory Message.user(String content) => Message(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        role: MessageRole.user,
        content: content,
      );

  factory Message.assistant(String content) {
    final blocks = CodeBlock.parseFromMarkdown(content);
    return Message(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: MessageRole.assistant,
      content: content,
      codeBlocks: blocks,
    );
  }

  // DB용 직렬화
  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'content': content,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory Message.fromJson(Map<String, dynamic> json) {
    final role = MessageRole.values.firstWhere(
      (r) => r.name == json['role'],
      orElse: () => MessageRole.user,
    );
    final content = json['content'] as String;
    return Message(
      id: json['id'] as String,
      role: role,
      content: content,
      codeBlocks: role == MessageRole.assistant
          ? CodeBlock.parseFromMarkdown(content)
          : [],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
    );
  }

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
}
