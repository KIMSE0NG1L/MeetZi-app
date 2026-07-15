import 'package:flutter/material.dart';
import 'package:nearo_app/shared/widgets/meetzy_sub_page_scaffold.dart';

class OpenSourceLicensesScreen extends StatelessWidget {
  const OpenSourceLicensesScreen({super.key});

  static const String _diceBearNotice =
      '본 서비스는 DiceBear에서 제공하는 오픈소스 아바타 생성 API(Lorelei 스타일)를 활용합니다.\n'
      '해당 리소스는 MIT 라이선스에 따라 사용되며, 상업적 이용이 가능합니다.\n'
      '관련 저작권은 원 저작자에게 있으며, 자세한 내용은 DiceBear 공식 문서를 참고하시기 바랍니다.';

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surfaceCard = dark ? const Color(0xFF374151) : Colors.white;
    final onSurface = dark ? Colors.white : const Color(0xFF111827);
    final onSurfaceVariant = dark ? Colors.grey.shade400 : Colors.grey.shade600;

    return MeetzySubPageScaffold(
      title: '오픈소스 라이선스',
      body: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DiceBear Lorelei',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SelectableText(
                        _diceBearNotice,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
      ),
    );
  }
}
