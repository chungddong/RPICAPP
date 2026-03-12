import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/code_block.dart';
import '../providers/connection_provider.dart';
import '../providers/execution_provider.dart';
import '../config/theme.dart';
import '../screens/connect_screen.dart';
import 'execution_result_card.dart';

class CodeBlockWidget extends ConsumerStatefulWidget {
  final CodeBlock block;

  const CodeBlockWidget({super.key, required this.block});

  @override
  ConsumerState<CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends ConsumerState<CodeBlockWidget> {
  bool _expanded = false;
  static const int _previewLines = 5;

  @override
  Widget build(BuildContext context) {
    final runningId = ref.watch(runningCodeIdProvider);
    final stateMap = ref.watch(executionStateProvider);
    final execState = stateMap[widget.block.id] ?? ExecutionState.idle;
    final isConnected = ref.watch(connectionProvider)?.isConnected ?? false;
    final isThisRunning = runningId == widget.block.id;

    final lines = widget.block.code.split('\n');
    final hasMore = lines.length > _previewLines;
    final displayCode =
        _expanded ? widget.block.code : lines.take(_previewLines).join('\n');

    return Container(
      decoration: BoxDecoration(
        color: kCodeBlockColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF45475A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 헤더 (언어 + 복사 + 접기/펼치기) ──
          InkWell(
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(8),
              bottom: (_expanded || !hasMore) ? Radius.zero : const Radius.circular(8),
            ),
            onTap: hasMore ? () => setState(() => _expanded = !_expanded) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF181825),
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  Text(
                    widget.block.language,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6C7086),
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // 복사 버튼
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: widget.block.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('코드 복사됨'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.copy, size: 15, color: Color(0xFF6C7086)),
                    ),
                  ),
                  if (hasMore) ...[
                    const SizedBox(width: 6),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 16,
                      color: const Color(0xFF6C7086),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── 코드 내용 ─────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: HighlightView(
              displayCode,
              language: widget.block.language,
              theme: atomOneDarkTheme,
              padding: const EdgeInsets.all(12),
              textStyle: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),

          // ── 더 보기 / 접기 ────────────
          if (hasMore)
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  _expanded ? '▲ 접기' : '▼ 더 보기 (${lines.length - _previewLines}줄)',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6C7086),
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),

          // ── 실행 버튼 / 결과 ──────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildActionButton(context, execState, isThisRunning, isConnected),
                if (execState == ExecutionState.success ||
                    execState == ExecutionState.error) ...[
                  const SizedBox(height: 8),
                  ExecutionResultCard(block: widget.block, execState: execState),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    ExecutionState execState,
    bool isThisRunning,
    bool isConnected,
  ) {
    if (isThisRunning) {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: kErrorColor),
        onPressed: () => ref.read(executionServiceProvider).stop(),
        icon: const Icon(Icons.stop, size: 16),
        label: const Text('⏹ 중지'),
      );
    }

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isConnected ? kSuccessColor : const Color(0xFF45475A),
        foregroundColor: isConnected ? Colors.black : Colors.white70,
      ),
      onPressed: () {
        if (isConnected) {
          ref.read(executionServiceProvider).runCode(widget.block);
        } else {
          // BLE 미연결 → ConnectScreen으로 이동 (뒤로 가기 가능)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ConnectScreen()),
          );
        }
      },
      icon: Icon(isConnected ? Icons.play_arrow : Icons.bluetooth, size: 16),
      label: Text(isConnected ? '▶ 실행' : 'BLE 연결 필요'),
    );
  }
}
