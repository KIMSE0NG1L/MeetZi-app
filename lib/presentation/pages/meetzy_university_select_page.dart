import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/core/theme/university_theme.dart';
import 'package:nearo_app/features/auth/data/environment_repository.dart';
import 'package:nearo_app/presentation/pages/meetzy_email_verification_page.dart';

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
  final EnvironmentRepository _repository = EnvironmentRepository();

  String _searchQuery = '';
  String? _selectedUniversity;
  bool _loading = true;
  List<MeetzyUniversityItem> _popularUniversities = [];
  List<MeetzyUniversityItem> _allUniversities = [];

  @override
  void initState() {
    super.initState();
    _loadUniversities();
  }

  Future<void> _loadUniversities() async {
    try {
      final ranking = await _repository.getRanking();
      final environments = await _repository.getEnvironments();

      final universities = environments
          .where((item) => item is Map && item['type']?.toString() == 'university')
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      final envByName = {
        for (final item in universities)
          (item['name']?.toString() ?? ''): item,
      };

      final popular = ranking
          .where((item) => (item['name']?.toString().trim().isNotEmpty ?? false) && envByName.containsKey(item['name']?.toString()))
          .take(10)
          .map(
            (item) => MeetzyUniversityItem(
              id: envByName[item['name']?.toString()]?['id']?.toString(),
              name: item['name']?.toString() ?? '-',
              count: (item['count'] as num?)?.toInt() ?? (item['users'] as num?)?.toInt() ?? 0,
              popular: true,
            ),
          )
          .toList();

      final all = universities
          .map(
            (item) => MeetzyUniversityItem(
              id: item['id']?.toString(),
              name: item['name']?.toString() ?? '-',
              count: 0,
            ),
          )
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      if (!mounted) return;
      setState(() {
        _popularUniversities = widget.universities ?? popular;
        _allUniversities = widget.universities ?? all;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _popularUniversities = widget.universities ?? const [];
        _allUniversities = widget.universities ?? const [];
        _loading = false;
      });
    }
  }

  List<MeetzyUniversityItem> get _filteredResults {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return _popularUniversities;
    }
    return _allUniversities.where((u) => u.name.toLowerCase().contains(query)).toList();
  }

  void _select(MeetzyUniversityItem item) {
    setState(() => _selectedUniversity = item.name);
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      if (widget.onComplete != null) {
        widget.onComplete!(item.name);
        return;
      }
      Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute(
          settings: RouteSettings(
            name: AppRoutes.emailVerification,
            arguments: item.name,
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = _filteredResults;
    final isSearching = _searchQuery.trim().isNotEmpty;

    return Scaffold(
      body: DecoratedBox(
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
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                decoration: const BoxDecoration(
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
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      onChanged: (value) => setState(() => _searchQuery = value),
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
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                        children: [
                          const Text(
                            '학교를 선택해주세요',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isSearching
                                ? '검색 결과에서 학교를 선택하세요'
                                : '인기 대학교는 실제 가입자 수 기준 상위 10개만 보여줘요',
                            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                          ),
                          const SizedBox(height: 24),
                          if (!isSearching) ...[
                            const Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 12),
                              child: Text(
                                '인기 대학교',
                                style: TextStyle(color: Color(0xFF6B7280), fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                          if (results.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 48),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.school, size: 64, color: Colors.grey.shade300),
                                    const SizedBox(height: 16),
                                    Text(
                                      isSearching ? '검색 결과가 없어요' : '아직 표시할 인기 대학교가 없어요',
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...results.map(_universityTile),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _universityTile(MeetzyUniversityItem item) {
    final selected = _selectedUniversity == item.name;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        shadowColor: selected ? const Color(0xFFEC4899).withValues(alpha: 0.3) : null,
        elevation: selected ? 4 : 0,
        child: InkWell(
          onTap: () => _select(item),
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
                    gradient: selected ? const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)]) : null,
                    color: selected ? null : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.school, size: 20, color: selected ? Colors.white : Colors.grey.shade600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      if (item.popular) ...[
                        const SizedBox(height: 4),
                        Text(
                          '가입자 ${item.count}명',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                        ),
                      ],
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
    this.id,
    this.count = 0,
    this.popular = false,
  });

  final String? id;
  final String name;
  final int count;
  final bool popular;
}
