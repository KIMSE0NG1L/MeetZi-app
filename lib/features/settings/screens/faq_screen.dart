import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';

/// 자주 묻는 질문 화면 (예시 FAQ)
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static final _items = [
    _FaqItem(
      question: '서비스는 어떻게 이용하나요?',
      answer: '같은 학교로 인증한 뒤, 게시판에서 마음에 드는 프로필을 열람할 수 있어요. '
          '열람권으로 프로필을 보고, 등록권으로 게시판에 올리면 매칭권을 받아요. '
          '가져가기로 관심을 표현하면 상대가 수락 시 매칭되고 대화를 나눌 수 있어요.',
    ),
    _FaqItem(
      question: '매칭·가져가기는 무엇인가요?',
      answer: '가져가기는 상대 프로필에 "관심 있어요"를 보내는 기능이에요. '
          '상대가 수락하면 매칭이 성사되고, 채팅방이 열려서 대화할 수 있어요. '
          '가져가기 1회당 매칭권 1장이 소모돼요.',
    ),
    _FaqItem(
      question: '코인·열람권·등록권은 어떻게 구매하나요?',
      answer: '앱 하단 상점 탭에서 코인을 충전할 수 있고, 코인으로 열람권(1코인=1장)과 '
          '등록권(5코인=1장)을 구매할 수 있어요. 100장 묶음 상품도 있어요.',
    ),
    _FaqItem(
      question: '계정을 삭제하려면 어떻게 하나요?',
      answer: '설정 화면 하단의 "계정 삭제"를 누르면 삭제할 수 있어요. '
          '삭제 시 프로필, 매칭 정보, 대화 내용 등 모든 데이터가 삭제되며 복구할 수 없어요.',
    ),
    _FaqItem(
      question: '문의는 어떻게 하나요?',
      answer: '고객센터 문의에서 문의 유형을 선택하고 내용을 입력한 뒤 보내주시면 돼요. '
          '답변은 앱 내 문의함에서 확인할 수 있어요. 운영시간에는 매일 수시로 확인하고 있어요 😊',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surfaceCard = dark ? const Color(0xFF374151) : Colors.white;
    final onSurface = dark ? Colors.white : const Color(0xFF111827);
    final onSurfaceVariant = dark ? Colors.grey.shade400 : Colors.grey.shade600;
    final topInset = MediaQuery.of(context).padding.top;
    final headerHeight = (topInset > 0 ? topInset : 56.0) + 20 + 36;

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
      body: Column(
        children: [
          Container(
            height: headerHeight,
            decoration: BoxDecoration(
              gradient: ThemeController.getHeaderGradient(),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 24),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        '자주 묻는 질문',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    elevation: 1,
                    shadowColor: Colors.black.withOpacity(0.06),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      iconColor: onSurfaceVariant,
                      collapsedIconColor: onSurfaceVariant,
                      title: Text(
                        item.question,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: onSurface,
                        ),
                      ),
                      children: [
                        Text(
                          item.answer,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;
  _FaqItem({required this.question, required this.answer});
}
