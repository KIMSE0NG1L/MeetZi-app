import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/shared/theme/nearo_theme.dart';

/// 홈 화면과 동일한 배경(흰색→rose-50 그라데이션)과 상단바 스타일(흰 배경 + 뒤로가기 + 제목)을
/// 쓰는 하위 페이지 공통 스캐폴드. 설정/공지/FAQ 등 "뒤로가기가 있는 페이지"에서 사용한다.
/// (하단 탭 화면 자체는 HomeShellScreen이 배경/상단바를 이미 그려주므로 여기 대상이 아님)
class MeetzySubPageScaffold extends StatelessWidget {
  const MeetzySubPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.onBack,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  /// 상단바 오른쪽에 넣을 위젯들. 지정하지 않으면 뒤로가기 버튼과 균형 맞춤용 빈 공간만 표시.
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: dark ? const Color(0xFF111827) : const Color(0xFFFFF1F2),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: Column(
        children: [
          _TopBar(title: title, actions: actions, onBack: onBack, dark: dark),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: dark ? null : NearoTheme.tabScreenBgGradient,
                color: dark ? const Color(0xFF111827) : null,
              ),
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.actions,
    required this.onBack,
    required this.dark,
  });

  final String title;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final pt = topInset > 0 ? topInset : 56.0;
    final iconColor = dark ? Colors.white : const Color(0xFF1F2937);
    return Container(
      height: pt + 20 + 36,
      width: double.infinity,
      color: dark ? const Color(0xFF111827) : Colors.white,
      child: Padding(
        padding: EdgeInsets.only(left: 4, right: 8, top: pt, bottom: 12),
        child: Row(
          children: [
            IconButton(
              icon: Icon(LucideIcons.arrowLeft, color: iconColor),
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (actions != null) ...actions! else const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}
