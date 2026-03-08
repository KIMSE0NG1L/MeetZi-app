import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kCoachMarkShownKey = 'meetzy_coach_mark_shown';

/// last CoachMark 1:1 — 첫 진입 시 단계별 안내 오버레이.
class MeetzyCoachMark extends StatefulWidget {
  const MeetzyCoachMark({
    super.key,
    required this.onComplete,
    required this.onSkip,
  });

  final VoidCallback onComplete;
  final VoidCallback onSkip;

  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_kCoachMarkShownKey) ?? false);
  }

  static Future<void> markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kCoachMarkShownKey, true);
  }

  @override
  State<MeetzyCoachMark> createState() => _MeetzyCoachMarkState();
}

class _MeetzyCoachMarkState extends State<MeetzyCoachMark> {
  int _currentStep = 0;

  static const _steps = [
    ('💝', '매칭권', '마음에 드는 사람에게 가져가기 요청을 보낼 때 사용하는 티켓이에요! 매칭대기함에서 요청을 확인해 보세요.'),
    ('🔔', '알림', '새로운 매칭 요청이나 메시지 알림을 확인할 수 있어요.'),
    ('⚙️', '설정', '다크모드, 컬러 테마 등 앱 설정을 변경할 수 있어요.'),
    ('🃏', '프로필 카드', '카드를 클릭하면 상세 프로필을 볼 수 있어요.'),
    ('🧭', '하단 네비게이션', '랭킹, 메시지, 게시판, 프로필, 상점을 자유롭게 이동할 수 있어요!'),
  ];

  void _next() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      MeetzyCoachMark.markShown();
      widget.onComplete();
    }
  }

  void _skip() {
    MeetzyCoachMark.markShown();
    widget.onSkip();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          GestureDetector(
            onTap: _skip,
            child: Container(color: Colors.black.withValues(alpha: 0.7)),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 320),
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFF1F2937) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFA855F7).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${_currentStep + 1}/${_steps.length}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFA855F7),
                                ),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: _skip,
                              icon: Icon(LucideIcons.x, size: 20, color: dark ? Colors.grey.shade400 : Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  step.$1,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    height: 1,
                                    fontFamilyFallback: ['Noto Color Emoji'],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    step.$2,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: dark ? Colors.white : const Color(0xFF111827),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              step.$3,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: dark ? Colors.grey.shade300 : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            if (_currentStep > 0)
                              TextButton(
                                onPressed: () => setState(() => _currentStep--),
                                child: Text('이전', style: TextStyle(color: dark ? Colors.grey.shade400 : Colors.grey.shade600)),
                              ),
                            const Spacer(),
                            FilledButton.icon(
                              onPressed: _next,
                              icon: const Icon(LucideIcons.chevronRight, size: 18),
                              label: Text(_currentStep == _steps.length - 1 ? '시작하기' : '다음'),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFA855F7),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_steps.length, (i) {
                            final active = i == _currentStep;
                            final done = i < _currentStep;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: active ? 24 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: active
                                    ? const Color(0xFFA855F7)
                                    : done
                                        ? const Color(0xFFA855F7).withValues(alpha: 0.5)
                                        : (dark ? Colors.grey.shade600 : Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
