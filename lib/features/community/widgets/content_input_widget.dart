import 'package:flutter/material.dart';

/// 포스트 본문 텍스트 입력 위젯
class ContentInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<int> onLengthChanged;
  final int maxLength;

  const ContentInputWidget({
    super.key,
    required this.controller,
    required this.onLengthChanged,
    this.maxLength = 1000,
  });

  @override
  State<ContentInputWidget> createState() => _ContentInputWidgetState();
}

class _ContentInputWidgetState extends State<ContentInputWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    widget.onLengthChanged(widget.controller.text.length);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final contentLength = widget.controller.text.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Text Input
        Container(
          decoration: BoxDecoration(
            color: dark ? Colors.grey.shade800.withOpacity(0.6) : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: dark ? Colors.grey.shade700 : Colors.grey.shade200,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            maxLines: null,
            minLines: 6,
            maxLength: widget.maxLength,
            decoration: InputDecoration(
              hintText: '무슨 생각을 하고 계신가요?',
              hintStyle: TextStyle(
                color: dark ? Colors.grey.shade500 : Colors.grey.shade500,
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              counterText: '',
            ),
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: dark ? Colors.white : Colors.black87,
            ),
            autofocus: true,
          ),
        ),
        const SizedBox(height: 4),
        // 글자 수 표시
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$contentLength / ${widget.maxLength}',
            style: TextStyle(
              fontSize: 12,
              color: dark ? Colors.grey.shade500 : Colors.grey.shade500,
            ),
          ),
        ),
      ],
    );
  }
}
