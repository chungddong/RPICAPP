enum ExecutionState { idle, running, success, error }

class CodeBlock {
  final String id;
  final String code;
  final String language;
  ExecutionState executionState;
  String? output;

  CodeBlock({
    required this.id,
    required this.code,
    this.language = 'python',
    this.executionState = ExecutionState.idle,
    this.output,
  });

  /// 마크다운 텍스트에서 코드블록 목록 파싱
  static List<CodeBlock> parseFromMarkdown(String text) {
    final regex = RegExp(r'```(\w+)?\n([\s\S]*?)```');
    final matches = regex.allMatches(text);
    return matches.map((m) {
      final lang = m.group(1) ?? 'text';
      final code = m.group(2)?.trim() ?? '';
      return CodeBlock(
        id: '${DateTime.now().millisecondsSinceEpoch}_${m.start}',
        code: code,
        language: lang,
      );
    }).toList();
  }

  CodeBlock copyWith({ExecutionState? state, String? output}) {
    return CodeBlock(
      id: id,
      code: code,
      language: language,
      executionState: state ?? executionState,
      output: output ?? this.output,
    );
  }
}
