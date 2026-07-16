import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/features/community/data/community_repository.dart';
import 'package:nearo_app/features/community/widgets/author_info_widget.dart';
import 'package:nearo_app/features/community/widgets/bottom_action_bar_widget.dart';
import 'package:nearo_app/features/community/widgets/community_guidelines_widget.dart';
import 'package:nearo_app/features/community/widgets/content_input_widget.dart';
import 'package:nearo_app/features/community/widgets/poll_input_widget.dart';
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
  int _contentLength = 0;

  static const _maxLength = 1000;

  @override
  void initState() {
    super.initState();
    _selectedTag = 'free';
  }

  @override
  void dispose() {
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
                    // 작성자 정보
                    AuthorInfoWidget(schoolName: widget.schoolName),
                    const SizedBox(height: 16),


                    // 콘텐츠 입력
                    ContentInputWidget(
                      controller: _contentController,
                      onLengthChanged: (length) => setState(() => _contentLength = length),
                      maxLength: _maxLength,
                    ),
                    const SizedBox(height: 20),

                    // 커뮤니티 가이드라인
                    const CommunityGuidelinesWidget(),
                    const SizedBox(height: 20),

                    // 투표 입력
                    PollInputWidget(
                      enabled: _addPoll,
                      onTogglePoll: () => setState(() => _addPoll = !_addPoll),
                      questionController: _pollQuestionController,
                      optionControllers: _optionControllers,
                      onAddOption: _addOption,
                      onRemoveOption: _removeOption,
                    ),
                  ],
                ),
              ),
            ),

            // 하단 액션 바
            BottomActionBarWidget(
              pollEnabled: _addPoll,
              onTogglePoll: () => setState(() => _addPoll = !_addPoll),
              isSending: _sending,
              canSubmit: canSubmit,
              onSubmit: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
