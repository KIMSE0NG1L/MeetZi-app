import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class NoticeListScreen extends StatelessWidget {
  const NoticeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('공지사항', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildNoticeItem(
            context,
            date: '2026-03-22',
            title: '[공지] Meetzi 업데이트 안내',
            content: 'Meetzi 서비스가 새롭게 단장되었습니다. 이제 더 빠르고 안정적인 매칭 서비스를 이용해 보세요!',
          ),
          // TODO: 서버 연동 후 동적으로 리스트 구성
        ],
      ),
    );
  }

  Widget _buildNoticeItem(BuildContext context, {required String date, required String title, required String content}) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NoticeDetailScreen(
                  title: title,
                  date: date,
                  content: content,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, height: 1.3),
                ),
                const SizedBox(height: 8),
                Text(
                  date,
                  style: TextStyle(color: dark ? Colors.white54 : Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NoticeDetailScreen extends StatelessWidget {
  final String title;
  final String date;
  final String content;

  const NoticeDetailScreen({
    super.key,
    required this.title,
    required this.date,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('공지사항', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(LucideIcons.clock, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  date,
                  style: TextStyle(
                    color: dark ? Colors.white54 : Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(),
            ),
            Text(
              content,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 60),
            Center(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                ),
                child: const Text('목록으로 돌아가기', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
