import 'package:flutter/material.dart';

/// 포스트 태그 선택을 전담하는 위젯
class PostTagSelector extends StatelessWidget {
  static const List<MapEntry<String, String>> postTags = [
    MapEntry('free', '자유'),
    MapEntry('love', '연애·썸'),
    MapEntry('matching_review', '소개팅·매칭후기'),
    MapEntry('counsel', '고민상담'),
    MapEntry('meme', '유머·밈'),
  ];

  final String selectedTag;
  final ValueChanged<String> onTagChanged;

  const PostTagSelector({
    super.key,
    required this.selectedTag,
    required this.onTagChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '주제 태그',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: dark ? Colors.grey.shade300 : const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: postTags.map((tag) {
            final selected = selectedTag == tag.key;
            return ChoiceChip(
              label: Text(tag.value),
              selected: selected,
              onSelected: (_) => onTagChanged(tag.key),
              selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              backgroundColor: dark ? Colors.grey.shade800 : Colors.grey.shade100,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : (dark ? Colors.grey.shade300 : Colors.grey.shade700),
              ),
              side: BorderSide(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : (dark ? Colors.grey.shade700 : Colors.grey.shade300),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
