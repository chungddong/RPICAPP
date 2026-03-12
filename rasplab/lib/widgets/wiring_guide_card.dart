import 'package:flutter/material.dart';

class WiringGuideCard extends StatefulWidget {
  final String content;

  const WiringGuideCard({super.key, required this.content});

  @override
  State<WiringGuideCard> createState() => _WiringGuideCardState();
}

class _WiringGuideCardState extends State<WiringGuideCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2B1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF3A6B3A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 헤더 (접기/펼치기) ──────────
          InkWell(
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(10),
              bottom: _expanded ? Radius.zero : const Radius.circular(10),
            ),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.cable, size: 16, color: Color(0xFFA6E3A1)),
                  const SizedBox(width: 8),
                  const Text(
                    '배선 연결 가이드',
                    style: TextStyle(
                      color: Color(0xFFA6E3A1),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFFA6E3A1),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          // ── 내용 ─────────────────────
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text(
                widget.content,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.7,
                  color: Color(0xFFCDD6F4),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
