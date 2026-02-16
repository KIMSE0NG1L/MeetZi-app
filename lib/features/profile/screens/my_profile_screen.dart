import 'package:flutter/material.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';
import 'package:nearo_app/shared/widgets/primary_button.dart';

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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _profile == null
                    ? const Center(child: Text('프로필 정보가 없습니다.'))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Center(
                              child: Container(
                                width: 340,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.18),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.10),
                                      blurRadius: 18,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 8),
                                    ),
                                    BoxShadow(
                                      color: Colors.brown.withOpacity(0.06),
                                      blurRadius: 2,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // 아바타 표시 (dicebear)
                                    if (_profile?['avatarSeed'] != null && (_profile?['avatarSeed'] as String).isNotEmpty)
                                      CircleAvatar(
                                        radius: 48,
                                        backgroundColor: Colors.white,
                                        child: ClipOval(
                                          child: SizedBox(
                                            width: 96,
                                            height: 96,
                                            child: SvgPicture.network(
                                              diceBearAvatarUrl(_profile!['avatarSeed'], options: _profile?['avatarOptions'] is Map<String, dynamic> ? (_profile!['avatarOptions'] as Map<String, dynamic>) : null),
                                              fit: BoxFit.cover,
                                              placeholderBuilder: (context) => Icon(Icons.person, size: 64, color: Theme.of(context).colorScheme.primary),
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      CircleAvatar(
                                        radius: 48,
                                        backgroundColor: Colors.white,
                                        child: Icon(Icons.person, size: 64, color: Theme.of(context).colorScheme.primary),
                                      ),
                                    const SizedBox(height: 18),
                                    Text(
                                      _profile?['nickname']?.toString() ?? '',
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 10),
                                    if (_profile?['heightCm'] != null)
                                      Text('키: ${_profile?['heightCm']} cm', style: TextStyle(fontSize: 16, color: Colors.grey[800])),
                                    if (_profile?['introOneLine'] != null && (_profile?['introOneLine'] as String).isNotEmpty)
                                      Text('한줄소개: ${_profile?['introOneLine']}', style: TextStyle(fontSize: 16, color: Colors.grey[800])),
                                    if (_profile?['gradeYear'] != null)
                                      Text('학년: ${_toLabel('gradeYear', _profile?['gradeYear'])}', style: TextStyle(fontSize: 16, color: Colors.grey[800])),
                                    if (_profile?['idealTypeKeywords'] is List && (_profile?['idealTypeKeywords'] as List).isNotEmpty)
                                      Text('나를 소개하는 키워드: ${(_profile?['idealTypeKeywords'] as List).join(", ")}', style: TextStyle(fontSize: 16, color: Colors.grey[800])),
                                    if (_profile?['fashionStyle'] != null && (_profile?['fashionStyle'] as String).isNotEmpty)
                                      Text('패션스타일: ${_toLabel('fashionStyle', _profile?['fashionStyle'])}', style: TextStyle(fontSize: 16, color: Colors.grey[800])),
                                    if (_profile?['activityTime'] != null && (_profile?['activityTime'] as String).isNotEmpty)
                                      Text('활동시간대: ${_toLabel('activityTime', _profile?['activityTime'])}', style: TextStyle(fontSize: 16, color: Colors.grey[800])),
                                    if (_profile?['idealType'] != null && (_profile?['idealType'] as String).isNotEmpty)
                                      Text('이상형: ${_profile?['idealType']}', style: TextStyle(fontSize: 16, color: Colors.grey[800])),
                                    if (_profile?['department'] != null && (_profile?['department'] as String).isNotEmpty)
                                      Text('학과: ${_profile?['department']}', style: TextStyle(fontSize: 16, color: Colors.grey[800])),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                            child: PrimaryButton(
                              label: '내 프로필 수정',
                              onPressed: () {
                                Navigator.of(context).pushNamed(
                                  AppRoutes.profileSetup,
                                  arguments: true,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }
}
