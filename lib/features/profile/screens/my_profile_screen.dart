import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';
import 'package:nearo_app/shared/utils/dicebear_avatar.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
    String _toLabel(String field, dynamic value) {
      final s = value?.toString().trim();
      if (s == null || s.isEmpty) return '-';
      switch (field) {
        case 'gradeYear':
          switch (s.toLowerCase()) {
            case 'one': return '1';
            case 'two': return '2';
            case 'three': return '3';
            case 'four': return '4';
            case 'five': return '5';
            case 'graduation_deferred': return '졸업유예';
            default: return s;
          }
        case 'fashionStyle':
          switch (s.toLowerCase()) {
            case 'hood_casual': return '후드/캐주얼';
            case 'shirt_neat': return '셔츠/단정';
            case 'street': return '스트릿';
            case 'knit': return '니트/감성';
            case 'sporty': return '체육복/스포티';
            case 'minimal': return '미니멀';
            case 'hip': return '힙한';
            default: return s;
          }
        case 'activityTime':
          switch (s.toLowerCase()) {
            case 'morning': return '아침형';
            case 'daytime': return '낮 활동형';
            case 'evening': return '저녁형';
            case 'night_owl': return '야행성';
            default: return s;
          }
        default:
          return s;
      }
    }
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await AuthRepository().getProfile();
      final profile = (res['user'] as Map<String, dynamic>?) ?? res as Map<String, dynamic>;
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF1F2937) : Colors.white;
    final onSurface = dark ? Colors.white : const Color(0xFF111827);
    final onSurfaceVariant = dark ? Colors.grey.shade400 : Colors.grey.shade600;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: onSurfaceVariant)))
              : _profile == null
                  ? Center(child: Text('프로필 정보가 없습니다.', style: TextStyle(color: onSurfaceVariant)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                        children: [
                          Material(
                            color: surface,
                            borderRadius: BorderRadius.circular(24),
                            elevation: 2,
                            shadowColor: Colors.black.withOpacity(0.06),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFFFECDD3), width: 4),
                                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12)],
                                        ),
                                        child: _profile?['avatarSeed'] != null && (_profile!['avatarSeed'] as String).isNotEmpty
                                            ? CircleAvatar(
                                                radius: 48,
                                                backgroundColor: Colors.white,
                                                child: ClipOval(
                                                  child: SizedBox(
                                                    width: 96,
                                                    height: 96,
                                                    child: SvgPicture.network(
                                                      diceBearAvatarUrl(
                                                        _profile!['avatarSeed'] as String,
                                                        options: _profile?['avatarOptions'] is Map<String, dynamic>
                                                            ? (_profile!['avatarOptions'] as Map<String, dynamic>).map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''))
                                                            : null,
                                                      ),
                                                      fit: BoxFit.cover,
                                                      placeholderBuilder: (context) => Icon(LucideIcons.user, size: 64, color: Theme.of(context).colorScheme.primary),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : CircleAvatar(
                                                radius: 48,
                                                backgroundColor: Colors.white,
                                                child: Icon(LucideIcons.user, size: 64, color: Theme.of(context).colorScheme.primary),
                                              ),
                                      ),
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(color: primary, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)]),
                                        child: const Icon(LucideIcons.camera, color: Colors.white, size: 18),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _profile?['nickname']?.toString() ?? '',
                                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: onSurface),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(LucideIcons.mapPin, size: 16, color: onSurfaceVariant),
                                      const SizedBox(width: 6),
                                      Text(
                                        _profile?['affiliationText']?.toString() ?? _profile?['school']?.toString() ?? '-',
                                        style: TextStyle(fontSize: 14, color: onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  Divider(height: 1, color: dark ? Colors.grey.shade700 : Colors.grey.shade200),
                                  const SizedBox(height: 16),
                                  _InfoRow(label: '소속', value: _profile?['affiliationText']?.toString() ?? _profile?['school']?.toString() ?? '-', onSurface: onSurface, onSurfaceVariant: onSurfaceVariant),
                                  _InfoRow(label: '성별', value: _profile?['gender']?.toString() == 'male' ? '남성' : '여성', onSurface: onSurface, onSurfaceVariant: onSurfaceVariant),
                                  _InfoRow(label: '학과', value: _profile?['department']?.toString() ?? '-', onSurface: onSurface, onSurfaceVariant: onSurfaceVariant),
                                  _InfoRow(label: '키', value: _profile?['heightCm'] != null ? '${_profile!['heightCm']}cm' : '-', onSurface: onSurface, onSurfaceVariant: onSurfaceVariant),
                                  _InfoRow(label: '학년', value: _toLabel('gradeYear', _profile?['gradeYear']), onSurface: onSurface, onSurfaceVariant: onSurfaceVariant),
                                  _InfoRow(label: 'MBTI', value: _profile?['mbti']?.toString() ?? '-', onSurface: onSurface, onSurfaceVariant: onSurfaceVariant),
                                  _InfoRow(label: '한줄소개', value: _profile?['introOneLine']?.toString() ?? '-', onSurface: onSurface, onSurfaceVariant: onSurfaceVariant),
                                  if (_profile?['idealTypeKeywords'] is List && (_profile!['idealTypeKeywords'] as List).isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Divider(height: 1, color: dark ? Colors.grey.shade700 : Colors.grey.shade200),
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text('관심사', style: TextStyle(fontSize: 14, color: onSurfaceVariant)),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: ((_profile!['idealTypeKeywords'] as List).map((e) => e?.toString() ?? '')).where((s) => s.isNotEmpty).map((tag) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: dark ? primary.withOpacity(0.3) : primary.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text('#$tag', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: dark ? primary.withOpacity(0.9) : primary)),
                                      )).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.of(context).pushNamed(AppRoutes.profileSetup, arguments: true),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  gradient: ThemeController.gradientFromPrimary(primary),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [BoxShadow(color: primary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(LucideIcons.pencil, color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text('내 프로필 수정', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, required this.onSurface, required this.onSurfaceVariant});
  final String label;
  final String value;
  final Color onSurface;
  final Color onSurfaceVariant;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: onSurfaceVariant)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: onSurface)),
        ],
      ),
    );
  }
}
