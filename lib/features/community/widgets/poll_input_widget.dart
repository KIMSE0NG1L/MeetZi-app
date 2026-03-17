import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 투표(Poll) 추가/삭제, 질문 입력, 선택지 관리를 전담하는 위젯
class PollInputWidget extends StatefulWidget {
  final bool enabled; // 투표 추가 여부
  final VoidCallback onTogglePoll;
  final TextEditingController questionController;
  final List<TextEditingController> optionControllers;
  final VoidCallback onAddOption;
  final Function(int) onRemoveOption;

  const PollInputWidget({
    super.key,
    required this.enabled,
    required this.onTogglePoll,
    required this.questionController,
    required this.optionControllers,
    required this.onAddOption,
    required this.onRemoveOption,
  });

  @override
  State<PollInputWidget> createState() => _PollInputWidgetState();
}

class _PollInputWidgetState extends State<PollInputWidget> {
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        // 투표 질문 입력
        TextField(
          controller: widget.questionController,
          decoration: InputDecoration(
            labelText: '투표 질문',
            hintText: '예: 오늘 점심 뭐 먹을까요?',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: _isDark ? Colors.grey.shade800 : Colors.grey.shade100,
          ),
          style: TextStyle(color: _isDark ? Colors.white : Colors.black87),
        ),
        const SizedBox(height: 12),
        // 선택지 헤더
        Text(
          '선택지 (2~10개)',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        // 선택지 목록
        ...List.generate(widget.optionControllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.optionControllers[index],
                    decoration: InputDecoration(
                      hintText: '선택지 ${index + 1}',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: _isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    ),
                    style: TextStyle(color: _isDark ? Colors.white : Colors.black87),
                  ),
                ),
                if (widget.optionControllers.length > 2)
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, size: 20),
                    onPressed: () => widget.onRemoveOption(index),
                    tooltip: '삭제',
                  ),
              ],
            ),
          );
        }),
        // 선택지 추가 버튼
        if (widget.optionControllers.length < 10)
          TextButton.icon(
            onPressed: widget.onAddOption,
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('선택지 추가'),
          ),
      ],
    );
  }
}
