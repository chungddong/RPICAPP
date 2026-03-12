import 'package:flutter/material.dart';
import '../models/code_block.dart';
import '../config/theme.dart';

class ExecutionResultCard extends StatelessWidget {
  final CodeBlock block;
  final ExecutionState execState;

  const ExecutionResultCard({
    super.key,
    required this.block,
    required this.execState,
  });

  @override
  Widget build(BuildContext context) {
    final isSuccess = execState == ExecutionState.success;
    final color = isSuccess ? kSuccessColor : kErrorColor;
    final icon = isSuccess ? Icons.check_circle_outline : Icons.error_outline;
    final label = isSuccess ? '실행 성공' : '실행 오류';
    final output = block.output ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (output.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              output,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Color(0xFFCDD6F4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
