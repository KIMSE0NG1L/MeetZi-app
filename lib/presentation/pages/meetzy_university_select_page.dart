import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// last UniversitySelectScreen 1:1 — gradient bg, 뒤로, 제목, 검색창, 인기/전체 대학교 리스트.
class MeetzyUniversitySelectPage extends StatefulWidget {
  const MeetzyUniversitySelectPage({
    super.key,
    required this.onComplete,
    required this.onBack,
    this.universities,
  });

  final void Function(String university) onComplete;
  final VoidCallback onBack;
  final List<MeetzyUniversityItem>? universities;

  @override
  State<MeetzyUniversitySelectPage> createState() => _MeetzyUniversitySelectPageState();
}

class _MeetzyUniversitySelectPageState extends State<MeetzyUniversitySelectPage> {
  String _searchQuery = '';
  String? _selectedUniversity;

  static const _defaultUniversities = [
    MeetzyUniversityItem(name: '세종대학교', location: '서울', popular: true),
    MeetzyUniversityItem(name: '서울대학교', location: '서울', popular: true),
    MeetzyUniversityItem(name: '연세대학교', location: '서울', popular: true),
    MeetzyUniversityItem(name: '고려대학교', location: '서울', popular: true),
    MeetzyUniversityItem(name: '성균관대학교', location: '서울', popular: true),
    MeetzyUniversityItem(name: '한양대학교', location: '서울', popular: true),
    MeetzyUniversityItem(name: '이화여자대학교', location: '서울', popular: true),
    MeetzyUniversityItem(name: '중앙대학교', location: '서울', popular: false),
    MeetzyUniversityItem(name: '경희대학교', location: '서울', popular: false),
    MeetzyUniversityItem(name: '한국외국어대학교', location: '서울', popular: false),
    MeetzyUniversityItem(name: '건국대학교', location: '서울', popular: false),
    MeetzyUniversityItem(name: '동국대학교', location: '서울', popular: false),
    MeetzyUniversityItem(name: '홍익대학교', location: '서울', popular: false),
    MeetzyUniversityItem(name: '숙명여자대학교', location: '서울', popular: false),
    MeetzyUniversityItem(name: '서울시립대학교', location: '서울', popular: false),
    MeetzyUniversityItem(name: '부산대학교', location: '부산', popular: false),
    MeetzyUniversityItem(name: '경북대학교', location: '대구', popular: false),
    MeetzyUniversityItem(name: '전남대학교', location: '광주', popular: false),
    MeetzyUniversityItem(name: '충남대학교', location: '대전', popular: false),
  ];

  List<MeetzyUniversityItem> get _filtered {
    final list = widget.universities ?? _defaultUniversities;
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.trim().toLowerCase();
    return list.where((u) => u.name.toLowerCase().contains(q)).toList();
  }

  void _select(String name) {
    setState(() => _selectedUniversity = name);
    Future.delayed(const Duration(milliseconds: 300), () {
      widget.onComplete(name);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final popular = filtered.where((u) => u.popular).toList();
    final other = filtered.where((u) => !u.popular).toList();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
            Color(0xFFEC4899),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton(
                    onPressed: widget.onBack,
                    child: Text(
                      '← 뒤로',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '학교를 선택해주세요',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '같은 학교 친구들과 만나보세요',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: '학교명 검색',
                      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                      prefixIcon: const Icon(LucideIcons.search, color: Color(0xFF9CA3AF), size: 20),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.95),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white.withValues(alpha: 0.05),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.school, size: 64, color: Colors.white.withValues(alpha: 0.4)),
                            const SizedBox(height: 16),
                            Text(
                              '검색 결과가 없습니다',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        children: [
                          if (popular.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                '🔥 인기 대학교',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            ...popular.map((u) => _uniTile(u)),
                            const SizedBox(height: 24),
                          ],
                          if (other.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                '전체 대학교',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            ...other.map((u) => _uniTile(u)),
                          ],
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _uniTile(MeetzyUniversityItem u) {
    final selected = _selectedUniversity == u.name;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white.withValues(alpha: selected ? 0.25 : 0.1),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _select(u.name),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? Colors.white : Colors.white.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.school, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(LucideIcons.mapPin, size: 12, color: Colors.white.withValues(alpha: 0.6)),
                          const SizedBox(width: 4),
                          Text(
                            u.location,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight, color: Colors.white.withValues(alpha: 0.6), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MeetzyUniversityItem {
  const MeetzyUniversityItem({
    required this.name,
    required this.location,
    this.popular = false,
  });
  final String name;
  final String location;
  final bool popular;
}
