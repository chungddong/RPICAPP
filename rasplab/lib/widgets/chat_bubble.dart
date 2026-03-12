import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../config/theme.dart';
import 'code_block_widget.dart';
import 'wiring_guide_card.dart';

class ChatBubble extends ConsumerWidget {
  final Message message;

  const ChatBubble({super.key, required this.message});

  // ── 배선 섹션 판별 기준 ──────────────────────────────────────────────
  static const _wiringKeywords = [
    'GPIO', 'GND', 'VCC', '→', 'SDA', 'SCL',
    '저항', 'Ω', '브레드보드', '점퍼', '양극', '음극',
  ];

  static final _wiringHeadingRe =
      RegExp(r'^#{1,3}\s*(배선|연결 방법|GPIO 연결|핀 연결|하드웨어 연결|배선도)', multiLine: false);

  static bool _isWiringParagraph(String para) {
    if (para.isEmpty) return false;
    // 배선 전용 헤딩
    if (_wiringHeadingRe.hasMatch(para)) return true;
    // "→" 포함 (핀 연결 화살표 표기)
    if (para.contains('→')) return true;
    // 2개 이상 키워드 포함
    final hitCount = _wiringKeywords.where((k) => para.contains(k)).length;
    return hitCount >= 2;
  }

  // ── 배선 섹션 추출 ────────────────────────────────────────────────────
  /// 코드 블록 제거 후, 배선 관련 단락을 합쳐서 반환. 없으면 빈 문자열.
  static String extractWiring(String content) {
    final noCode = content.replaceAll(RegExp(r'```[\s\S]*?```'), '').trim();
    final paragraphs = noCode.split(RegExp(r'\n{2,}'));
    final wiring = <String>[];

    String? pendingHeading;
    for (final p in paragraphs) {
      final t = p.trim();
      if (t.isEmpty) continue;
      // 배선 헤딩 감지 → 다음 단락과 묶기
      if (_wiringHeadingRe.hasMatch(t)) {
        pendingHeading = t;
        continue;
      }
      if (pendingHeading != null) {
        wiring.add('$pendingHeading\n$t');
        pendingHeading = null;
        continue;
      }
      if (_isWiringParagraph(t)) {
        wiring.add(t);
      }
    }
    // 마지막 헤딩만 있고 내용이 없는 경우
    if (pendingHeading != null) wiring.add(pendingHeading);

    return wiring.join('\n\n');
  }

  // ── 표시용 순수 텍스트 추출 ───────────────────────────────────────────
  /// 코드 블록, 배선 단락, 마크다운 기호 제거 후 clean text 반환.
  static String extractCleanText(String content) {
    // 1) 코드 블록 제거
    String s = content.replaceAll(RegExp(r'```[\s\S]*?```'), '').trim();
    // 2) 단락 분리
    final paragraphs = s.split(RegExp(r'\n{2,}'));
    // 3) 배선 단락 제거
    final textParas = paragraphs.where((p) => !_isWiringParagraph(p.trim())).toList();
    // 4) 마크다운 헤딩 기호, bold 기호 제거
    final cleaned = textParas.map((p) {
      return p
          .trim()
          .replaceAll(RegExp(r'^#{1,4}\s+', multiLine: true), '')
          .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1')
          .replaceAll(RegExp(r'\*(.+?)\*'), r'$1')
          .trim();
    }).where((p) => p.isNotEmpty).join('\n\n');
    return cleaned.trim();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUser = message.isUser;

    // 로딩 말풍선
    if (message.content == '...') {
      return _buildLoadingBubble();
    }

    if (isUser) {
      return _buildUserBubble();
    }

    // AI 말풍선
    final cleanText = extractCleanText(message.content);
    final wiringText = extractWiring(message.content);
    // Python 코드 블록만 표시
    final pythonBlocks = message.codeBlocks
        .where((b) => b.language == 'python')
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI 아바타
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFF82AAFF),
            child: Text('AI', style: TextStyle(fontSize: 10, color: Colors.black)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 텍스트 말풍선 ──────────────────────
                if (cleanText.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: const BoxDecoration(
                      color: kAiBubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(18),
                      ),
                    ),
                    child: Text(
                      cleanText,
                      style: const TextStyle(fontSize: 14, height: 1.6),
                    ),
                  ),

                // ── 배선 연결 가이드 카드 ──────────────
                if (wiringText.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  WiringGuideCard(content: wiringText),
                ],

                // ── Python 코드블록 카드들 ─────────────
                for (final block in pythonBlocks) ...[
                  const SizedBox(height: 6),
                  CodeBlockWidget(block: block),
                ],
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserBubble() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: kUserBubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Text(
                message.content,
                style: const TextStyle(fontSize: 14, height: 1.6),
              ),
            ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFF82AAFF),
            child: Text('AI', style: TextStyle(fontSize: 10, color: Colors.black)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: const BoxDecoration(
              color: kAiBubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: const SizedBox(
              width: 48,
              child: LinearProgressIndicator(),
            ),
          ),
        ],
      ),
    );
  }
}

