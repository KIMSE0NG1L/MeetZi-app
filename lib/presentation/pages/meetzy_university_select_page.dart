import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/core/theme/university_theme.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/presentation/pages/meetzy_email_verification_page.dart';

/// ad UniversitySelectScreen 100% — gradient header, 검색창, "학교를 선택해주세요 🎓", 인기/전체 대학교, 흰 카드·핑크 선택.
class MeetzyUniversitySelectPage extends StatefulWidget {
  const MeetzyUniversitySelectPage({
    super.key,
    this.onComplete,
    required this.onBack,
    this.universities,
  });

  final void Function(String university)? onComplete;
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
      if (!mounted) return;
      if (widget.onComplete != null) {
        widget.onComplete!(name);
      } else {
        Navigator.of(context).pushReplacement<void, void>(
          MaterialPageRoute(
            settings: RouteSettings(
              name: AppRoutes.emailVerification,
              arguments: name,
            ),
            builder: (ctx) => MeetzyEmailVerificationPage(
              onBack: () => Navigator.of(ctx).pushReplacementNamed(AppRoutes.universitySelect),
              onComplete: () => Navigator.of(ctx).pushReplacementNamed(
                AppRoutes.profileSetup,
                arguments: {'isInitialSetup': true},
              ),
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final popular = filtered.where((u) => u.popular).toList();
    final other = filtered.where((u) => !u.popular).toList();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              UniversityTheme.bgGradientStart,
              UniversityTheme.bgGradientMid,
              UniversityTheme.bgGradientEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header (ad: bg-gradient-to-r themeColors.gradient)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
                decoration: BoxDecoration(
                  gradient: UniversityTheme.designPinkGradient,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: widget.onBack,
                          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 24),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const Text(
                          '학교 선택',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // 검색창 (ad: white/95 rounded-2xl)
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
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              // Content (ad: 학교를 선택해주세요 🎓, 같은 학교 친구들과 만나보세요)
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      '학교를 선택해주세요 🎓',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '같은 학교 친구들과 만나보세요',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (filtered.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 48),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.school, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                '검색 결과가 없습니다',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      if (popular.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            '🔥 인기 대학교',
                            style: TextStyle(
                              color: Colors.grey.shade600,
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
                          padding: const EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            '전체 대학교',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ...other.map((u) => _uniTile(u)),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _uniTile(MeetzyUniversityItem u) {
    final selected = _selectedUniversity == u.name;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        shadowColor: selected ? const Color(0xFFEC4899).withValues(alpha: 0.3) : null,
        elevation: selected ? 4 : 0,
        child: InkWell(
          onTap: () => _select(u.name),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? const Color(0xFFEC4899) : const Color(0xFFE5E7EB),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(
                            colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                          )
                        : null,
                    color: selected ? null : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.school,
                    size: 20,
                    color: selected ? Colors.white : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.name,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(LucideIcons.mapPin, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            u.location,
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight, color: Colors.grey.shade400, size: 20),
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
