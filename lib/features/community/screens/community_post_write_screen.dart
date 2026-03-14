import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/features/community/data/community_repository.dart';
import 'package:nearo_app/shared/theme/nearo_theme.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';

class CommunityPostWriteScreen extends StatefulWidget {
  final String environmentId;
  final String schoolName;
  final String? initialTag;

  const CommunityPostWriteScreen({
    super.key,
    required this.environmentId,
    required this.schoolName,
    this.initialTag,
  });

  @override
  State<CommunityPostWriteScreen> createState() => _CommunityPostWriteScreenState();
}

class _CommunityPostWriteScreenState extends State<CommunityPostWriteScreen> {
  static const List<MapEntry<String, String>> _postTags = [
    MapEntry('free', '\uC790\uC720'),
    MapEntry('love', '\uC5F0\uC560\u00B7\uC36C'),
    MapEntry('matching_review', '\uC18C\uAC1C\uD305\u00B7\uB9E4\uCE6D\uD6C4\uAE30'),
    MapEntry('counsel', '\uACE0\uBBFC\uC0C1\uB2F4'),
    MapEntry('meme', '\uC720\uBA38\u00B7\uBC08'),
  ];

  final CommunityRepository _repo = CommunityRepository();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _pollQuestionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _sending = false;
  bool _addPoll = false;
  String _selectedTag = 'free';

  static const _maxLength = 1000;

  @override
  void initState() {
    super.initState();
    final allowed = _postTags.map((e) => e.key).toSet();
    final initial = widget.initialTag;
    if (initial != null && allowed.contains(initial)) {
      _selectedTag = initial;
    }
    _contentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _contentController.removeListener(() => setState(() {}));
    _contentController.dispose();
    _pollQuestionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length >= 10) return;
    setState(() => _optionControllers.add(TextEditingController()));
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) return;
    _optionControllers[index].dispose();
    setState(() => _optionControllers.removeAt(index));
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;
    Map<String, dynamic>? poll;
    if (_addPoll) {
      final question = _pollQuestionController.text.trim();
      final options = _optionControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
      if (question.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('투표 질문을 입력해 주세요.')),
        );
        return;
      }
      if (options.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('선택지는 최소 2개 이상 필요해요.')),
        );
        return;
      }
      poll = {'question': question, 'options': options};
    }
    setState(() => _sending = true);
    try {
      await _repo.createPost(
        widget.environmentId,
        content,
        tag: _selectedTag,
        poll: poll,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        String message = '글 등록에 실패했어요. 잠시 후 다시 시도해 주세요.';
        if (e is DioException) {
          final code = e.response?.statusCode;
          if (code == 401) {
            message = '로그인이 필요해요. 앱을 다시 실행하거나 다시 로그인해 주세요.';
          } else if (code == 404) {
            message = '커뮤니티를 찾을 수 없어요.';
          } else if (code != null && code >= 500) {
            message = '서버 오류가 났어요. 잠시 후 다시 시도해 주세요.';
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final contentLength = _contentController.text.length;
    final canSubmit = _contentController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '글쓰기',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: ThemeController.getHeaderGradient()),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: dark ? null : ThemeController.getScreenBgGradient(),
          color: dark ? NearoTheme.designScreenBgDark : null,
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
            // Author Info
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE5E7EB),
                    border: Border.all(
                      color: dark ? Colors.grey.shade600 : Colors.grey.shade300,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(LucideIcons.user, size: 24, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '작성자',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: dark ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.schoolName,
                        style: TextStyle(
                          fontSize: 12,
                          color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              '\uC8FC\uC81C \uD0DC\uADF8',
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
              children: _postTags.map((tag) {
                final selected = _selectedTag == tag.key;
                return ChoiceChip(
                  label: Text(tag.value),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedTag = tag.key),
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
            const SizedBox(height: 16),

            // Text Input (Design: rounded, placeholder, 0/1000)
            Container(
              decoration: BoxDecoration(
                color: dark ? Colors.grey.shade800.withOpacity(0.6) : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: dark ? Colors.grey.shade700 : Colors.grey.shade200,
                ),
              ),
              child: TextField(
                controller: _contentController,
                maxLines: null,
                minLines: 6,
                maxLength: _maxLength,
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
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$contentLength / $_maxLength',
                style: TextStyle(
                  fontSize: 12,
                  color: dark ? Colors.grey.shade500 : Colors.grey.shade500,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Community Guidelines (Design: 📌 커뮤니티 가이드라인)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: dark ? Colors.grey.shade800.withOpacity(0.4) : Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '📌',
                        style: TextStyle(fontSize: 14, color: dark ? Colors.grey.shade400 : Colors.grey.shade700),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '커뮤니티 가이드라인',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: dark ? Colors.grey.shade300 : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _guideline('타인을 존중하는 표현을 사용해주세요'),
                  _guideline('개인정보 노출에 주의해주세요'),
                  _guideline('허위사실 유포는 삼가주세요'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_addPoll) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _pollQuestionController,
                decoration: InputDecoration(
                  labelText: '투표 질문',
                  hintText: '예: 오늘 점심 뭐 먹을까요?',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: dark ? Colors.grey.shade800 : Colors.grey.shade100,
                ),
                style: TextStyle(color: dark ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 12),
              Text(
                '선택지 (2~10개)',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              ...List.generate(_optionControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _optionControllers[index],
                          decoration: InputDecoration(
                            hintText: '선택지 ${index + 1}',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            filled: true,
                            fillColor: dark ? Colors.grey.shade800 : Colors.grey.shade100,
                          ),
                          style: TextStyle(color: dark ? Colors.white : Colors.black87),
                        ),
                      ),
                      if (_optionControllers.length > 2)
                        IconButton(
                          icon: const Icon(LucideIcons.trash2, size: 20),
                          onPressed: () => _removeOption(index),
                          tooltip: '삭제',
                        ),
                    ],
                  ),
                );
              }),
              if (_optionControllers.length < 10)
                TextButton.icon(
                  onPressed: _addOption,
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: const Text('선택지 추가'),
                ),
            ],
          ],
        ),
      ),
      ),
            const SizedBox(height: 24),
            // 하단 바: + 버튼 + 게시하기 버튼
            SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: dark ? Colors.grey.shade800 : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // 투표 추가 (+ 버튼으로 토글)
                    Material(
                      color: _addPoll
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                          : (dark ? Colors.grey.shade700 : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => setState(() => _addPoll = !_addPoll),
                        borderRadius: BorderRadius.circular(12),
                        child: Tooltip(
                          message: _addPoll ? '투표 제거' : '투표 추가',
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Center(
                              child: Icon(
                                _addPoll ? LucideIcons.vote : LucideIcons.plus,
                                size: 24,
                                color: _addPoll
                                    ? Theme.of(context).colorScheme.primary
                                    : const Color(0xFF4B5563),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Material(
                        color: dark ? Colors.grey.shade700 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: _sending || !canSubmit ? null : _submit,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_sending)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                else ...[
                                  Icon(
                                    LucideIcons.send,
                                    size: 20,
                                    color: canSubmit
                                        ? (dark ? Colors.grey.shade200 : const Color(0xFF4B5563))
                                        : (dark ? Colors.grey.shade500 : Colors.grey.shade400),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '게시하기',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: canSubmit
                                          ? (dark ? Colors.grey.shade200 : const Color(0xFF4B5563))
                                          : (dark ? Colors.grey.shade500 : Colors.grey.shade400),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _guideline(String text) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 13,
              color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
