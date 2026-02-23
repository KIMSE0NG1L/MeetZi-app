import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';
import 'package:nearo_app/features/auth/data/environment_repository.dart';
import 'package:nearo_app/features/photo/data/photo_repository.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';
import 'package:nearo_app/shared/utils/app_config.dart';
import 'package:nearo_app/shared/utils/dicebear_avatar.dart';
import 'package:nearo_app/shared/widgets/primary_button.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 한글(가나다) 먼저, 영어/로마자 학교명은 맨 아래로 정렬
void _sortSchoolListKoreanFirst(List<String> list) {
  bool startsWithHangul(String s) {
    if (s.isEmpty) return false;
    final c = s.codeUnitAt(0);
    return c >= 0xAC00 && c <= 0xD7A3; // 가-힣
  }
  list.sort((a, b) {
    final aFirst = startsWithHangul(a) ? 0 : 1;
    final bFirst = startsWithHangul(b) ? 0 : 1;
    if (aFirst != bFirst) return aFirst - bFirst;
    return a.compareTo(b);
  });
}

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _repository = AuthRepository();
  final _photoRepository = PhotoRepository();
  final _envRepository = EnvironmentRepository();
  final _nicknameController = TextEditingController();
  final _idealTypeController = TextEditingController();
  final _departmentController = TextEditingController();
  String _affiliation = '세종대학교';
  List<String> _schoolList = [];
  bool _schoolListLoaded = false;
  final _heightController = TextEditingController();
  final _mbtiController = TextEditingController();
  final _introOneLineController = TextEditingController();
  final _intoLatelyController = TextEditingController();
  String _gender = 'male';
  String _preferredGender = 'opposite';
  String? _smoking;
  String? _drinking;
  String? _gradeYear;
  List<String> _idealTypeKeywords = [];
  String? _fashionStyle;
  String? _preferredDateType;
  String? _activityTime;
  int? _heightCm; // 150~195 스크롤용
  String? _avatarSeed;
  String? _avatarStyle;
  Map<String, String> _avatarOptions = {};
  bool _isLoading = false;
  String _result = '';
  bool _isEditing = false;
  bool _forceEdit = false;
  bool _didReadArgs = false;
  XFile? _selectedPhoto;
  List<dynamic> _photos = [];
  bool _isUploadingPhoto = false;
  String? _photoError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadArgs) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is bool) {
      _forceEdit = args;
    }
    _didReadArgs = true;
    _loadProfileIfExists();
    _loadSchoolList();
  }

  Future<void> _loadSchoolList() async {
    try {
      final list = await _envRepository.getEnvironments();
      final names = list
          .where((e) => e is Map && (e as Map)['type']?.toString() == 'university')
          .map<String>((e) => (e as Map)['name']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
      _sortSchoolListKoreanFirst(names);
      if (!mounted) return;
      setState(() {
        _schoolList = names;
        _schoolListLoaded = true;
        if (_schoolList.isNotEmpty && !_schoolList.contains(_affiliation)) {
          _affiliation = _schoolList.first;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _schoolList = ['세종대학교', '건국대학교', '한양대학교'];
        _schoolListLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _heightController.dispose();
    _mbtiController.dispose();
    _idealTypeController.dispose();
    _departmentController.dispose();
    _introOneLineController.dispose();
    _intoLatelyController.dispose();
    super.dispose();
  }

  static const List<String> _idealKeywordOptions = [
    '귀여운', '다정한', '장난기 많은', '차분한', '지적인',
    '운동 좋아하는', '패션 감각 있는', '집돌이/집순이', '외향적인', '솔직한',
  ];
  static const List<String> _gradeYearOptions = ['1', '2', '3', '4', '5', '졸업유예'];
  static const List<String> _gradeYearValues = ['one', 'two', 'three', 'four', 'five', 'graduation_deferred'];
  static const List<String> _mbtiOptions = [
    'INTJ', 'INTP', 'ENTJ', 'ENTP', 'INFJ', 'INFP', 'ENFJ', 'ENFP',
    'ISTJ', 'ISFJ', 'ESTJ', 'ESFJ', 'ISTP', 'ISFP', 'ESTP', 'ESFP',
  ];
  static const List<MapEntry<String, String>> _fashionOptions = [
    MapEntry('hood_casual', '후드/캐주얼'),
    MapEntry('shirt_neat', '셔츠/단정'),
    MapEntry('street', '스트릿'),
    MapEntry('knit', '니트/감성'),
    MapEntry('sporty', '체육복/스포티'),
    MapEntry('minimal', '미니멀'),
    MapEntry('hip', '힙한'),
  ];
  static const List<MapEntry<String, String>> _dateTypeOptions = [
    MapEntry('cafe', '카페 탐방'),
    MapEntry('walk', '산책'),
    MapEntry('movie', '영화'),
    MapEntry('drink', '술 한잔'),
    MapEntry('exercise', '운동'),
    MapEntry('food_tour', '맛집 투어'),
    MapEntry('drive', '드라이브'),
  ];
  static const List<MapEntry<String, String>> _activityTimeOptions = [
    MapEntry('morning', '아침형'),
    MapEntry('daytime', '낮 활동형'),
    MapEntry('evening', '저녁형'),
    MapEntry('night_owl', '야행성'),
  ];

  Future<void> _loadProfileIfExists() async {
    try {
      final result = await _repository.getProfile();
      final user = (result['user'] as Map?) ?? result;
      final nickname = user['nickname']?.toString();
      final gender = user['gender']?.toString();
      final affiliation = user['affiliationText']?.toString();

      if (nickname != null) {
        _nicknameController.text = nickname;
      }
      if (gender != null) {
        _gender = gender;
      }
      if (affiliation != null && affiliation.isNotEmpty) {
        _affiliation = affiliation;
      }
      final heightCm = user['heightCm'];
      if (heightCm != null) {
        _heightController.text = heightCm.toString();
      }
      final smoking = user['smoking']?.toString();
      final drinking = user['drinking']?.toString();
      if (smoking != null) _smoking = smoking;
      if (drinking != null) _drinking = drinking;
      final mbti = user['mbti']?.toString();
      if (mbti != null) _mbtiController.text = mbti;

      final idealType = user['idealType']?.toString();
      if (idealType != null) _idealTypeController.text = idealType;
      final department = user['department']?.toString();
      if (department != null) _departmentController.text = department;
      final introOneLine = user['introOneLine']?.toString();
      if (introOneLine != null) _introOneLineController.text = introOneLine;
      final intoLately = user['intoLately']?.toString();
      if (intoLately != null) _intoLatelyController.text = intoLately;
      final gradeYear = user['gradeYear']?.toString();
      if (gradeYear != null) _gradeYear = gradeYear;
      final keywords = user['idealTypeKeywords'];
      if (keywords is List) {
        _idealTypeKeywords = keywords.map((e) => e.toString()).toList();
      }
      final fashion = user['fashionStyle']?.toString();
      if (fashion != null) _fashionStyle = fashion;
      final dateType = user['preferredDateType']?.toString();
      if (dateType != null) _preferredDateType = dateType;
      final activity = user['activityTime']?.toString();
      if (activity != null) _activityTime = activity;
      if (heightCm != null) _heightCm = heightCm is int ? heightCm : (heightCm as num).toInt();
      final avatarSeed = user['avatarSeed']?.toString();
      final avatarStyle = user['avatarStyle']?.toString();
      if (avatarSeed != null) _avatarSeed = avatarSeed;
      if (avatarStyle != null) _avatarStyle = avatarStyle;
      final avatarOptionsRaw = user['avatarOptions']?.toString();
      if (avatarOptionsRaw != null && avatarOptionsRaw.isNotEmpty) {
        try {
          final decoded = jsonDecode(avatarOptionsRaw);
          if (decoded is Map<String, dynamic>) {
            _avatarOptions = decoded.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
          }
        } catch (_) {}
      }

      setState(() {
        _isEditing = _forceEdit || (affiliation != null && affiliation.isNotEmpty);
      });
      await _loadPhotos();
    } catch (_) {
      // ignore if profile not found
    }
  }

  Future<void> _loadPhotos() async {
    try {
      final photos = await _photoRepository.getMyPhotos();
      if (!mounted) return;
      setState(() => _photos = photos);
    } catch (_) {
      if (!mounted) return;
      setState(() => _photoError = '사진을 불러오지 못했습니다.');
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() {
      _selectedPhoto = file;
      _photoError = null;
    });
  }

  Future<void> _uploadSelectedPhoto() async {
    if (_selectedPhoto == null) {
      setState(() => _photoError = '먼저 사진을 선택해 주세요.');
      return;
    }
    setState(() {
      _isUploadingPhoto = true;
      _photoError = null;
    });
    try {
      await _photoRepository.uploadPhotoFile(file: _selectedPhoto!);
      if (!mounted) return;
      setState(() => _selectedPhoto = null);
      await _loadPhotos();
    } on DioException catch (error) {
      setState(() => _photoError = error.response?.data.toString() ?? '업로드 실패');
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  String _resolvePhotoUrl(String storageKey) {
    if (storageKey.startsWith('http')) return storageKey;
    if (storageKey.startsWith('/')) return '${AppConfig.baseUrl}$storageKey';
    return '${AppConfig.baseUrl}/$storageKey';
  }

  /// 닉네임: 2~8자, 한글/영문/숫자만, 특수문자·공백 불가
  static bool _isValidNickname(String s) {
    final t = s.trim();
    if (t.length < 2 || t.length > 8) return false;
    return RegExp(r'^[가-힣a-zA-Z0-9]+$').hasMatch(t);
  }

  Future<void> _submit() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      setState(() => _result = '닉네임을 입력해 주세요.');
      return;
    }
    if (!_isValidNickname(nickname)) {
      setState(() => _result = '닉네임은 2~8자, 한글/영문/숫자만 가능하며 특수문자·공백은 불가합니다.');
      return;
    }

    final heightCm = _heightCm ?? int.tryParse(_heightController.text.trim());
    if (heightCm != null && (heightCm < 150 || heightCm > 195)) {
      setState(() => _result = '키는 150~195cm 범위로 입력해 주세요.');
      return;
    }

    final preferredGenders = switch (_preferredGender) {
      'male' => ['male'],
      'female' => ['female'],
      'all' => ['male', 'female'],
      _ => _gender == 'male' ? ['female'] : ['male'],
    };

    setState(() => _isLoading = true);
    try {
      final response = await _repository.updateProfile({
        'nickname': nickname,
        'gender': _gender,
        'affiliationText': _affiliation,
        if (heightCm != null) 'heightCm': heightCm,
        if (_smoking != null) 'smoking': _smoking,
        if (_drinking != null) 'drinking': _drinking,
        if (_mbtiController.text.trim().isNotEmpty)
          'mbti': _mbtiController.text.trim(),
        if (_idealTypeController.text.trim().isNotEmpty)
          'idealType': _idealTypeController.text.trim(),
        if (_departmentController.text.trim().isNotEmpty)
          'department': _departmentController.text.trim(),
        'preferredGenders': preferredGenders,
        if (_gradeYear != null) 'gradeYear': _gradeYear,
        if (_introOneLineController.text.trim().isNotEmpty)
          'introOneLine': _introOneLineController.text.trim().length > 40
              ? _introOneLineController.text.trim().substring(0, 40)
              : _introOneLineController.text.trim(),
        if (_idealTypeKeywords.isNotEmpty) 'idealTypeKeywords': _idealTypeKeywords,
        if (_fashionStyle != null) 'fashionStyle': _fashionStyle,
        if (_preferredDateType != null) 'preferredDateType': _preferredDateType,
        if (_activityTime != null) 'activityTime': _activityTime,
        if (_intoLatelyController.text.trim().isNotEmpty)
          'intoLately': _intoLatelyController.text.trim().length > 20
              ? _intoLatelyController.text.trim().substring(0, 20)
              : _intoLatelyController.text.trim(),
      });
      _applyThemeForAffiliation();
      setState(() => _result = response.toString());
      if (!mounted) return;
      if (_isEditing) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.home,
          (route) => false,
        );
      } else {
        Navigator.of(context).pushNamed(AppRoutes.environment);
      }
    } on DioException catch (error) {
      String msg = '요청 실패';
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        msg = data['message'].toString();
      } else if (data != null) {
        msg = data.toString();
      }
      setState(() => _result = msg);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyThemeForAffiliation() {
    switch (_affiliation) {
      case '세종대학교':
        ThemeController.setSeedColor(const Color(0xFFB93234));
        break;
      case '건국대학교':
        ThemeController.setSeedColor(const Color(0xFF036B3F));
        break;
      case '한양대학교':
        ThemeController.setSeedColor(const Color(0xFF1D2475));
        break;
    }
  }

  /// AppDesign ProfileEditScreen: 흰색 헤더 (뒤로가기, 프로필 수정), bg-gray-50 본문
  Widget _buildAppDesignHeader(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final pt = topInset > 0 ? topInset : 56.0;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(left: 20, right: 20, top: pt, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(LucideIcons.arrowLeft, size: 22, color: Color(0xFF374151)),
            padding: const EdgeInsets.all(8),
          ),
          Text(
            _isEditing ? '프로필 수정' : '프로필 등록',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  static const _inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide.none,
  );
  static const _labelStyle = TextStyle(fontSize: 14, color: Color(0xFF6B7280));
  static const _sectionLabelStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827));

  @override
  Widget build(BuildContext context) {
    const bgGray50 = Color(0xFFF9FAFB);
    return Scaffold(
      backgroundColor: bgGray50,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            elevation: 1,
            shadowColor: Colors.black.withOpacity(0.06),
            color: Colors.white,
            child: _buildAppDesignHeader(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  const Text('아바타', style: _sectionLabelStyle),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: _avatarSeed != null && _avatarSeed!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(40),
                                child: SvgPicture.network(
                                  diceBearAvatarUrl(_avatarSeed!, options: _avatarOptions.isNotEmpty ? _avatarOptions : null),
                                  fit: BoxFit.cover,
                                  placeholderBuilder: (context) => const Center(child: CircularProgressIndicator()),
                                ),
                              )
                            : Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(LucideIcons.user, size: 40, color: Colors.grey.shade600),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            await Navigator.of(context).pushNamed(AppRoutes.avatarSetup);
                            if (!mounted) return;
                            _loadProfileIfExists();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFD1D5DB), width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('아바타 편집', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('프로필 사진', style: _sectionLabelStyle),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _selectedPhoto == null
                            ? const Icon(LucideIcons.upload, size: 32, color: Color(0xFF9CA3AF))
                            : Image.file(
                                File(_selectedPhoto!.path),
                                fit: BoxFit.cover,
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _pickPhoto,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFD1D5DB), width: 2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text('사진 선택', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _isUploadingPhoto ? null : _uploadSelectedPhoto,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [Color(0xFFF43F5E), Color(0xFFEC4899)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [BoxShadow(color: const Color(0xFFF43F5E).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
                                  ),
                                  child: _isUploadingPhoto
                                      ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                                      : const Text('사진 업로드', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              if (_photoError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _photoError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (_photos.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 88,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _photos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final photo = _photos[index] as Map<String, dynamic>;
                      final storageKey = photo['storageKey']?.toString() ?? '';
                      final isPrimary = photo['isPrimary'] == true;
                      return Stack(
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey.shade100,
                              border: Border.all(
                                color: isPrimary
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: storageKey.isEmpty
                                ? const Icon(LucideIcons.imageOff)
                                : Image.network(
                                    _resolvePhotoUrl(storageKey),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          if (isPrimary)
                            Positioned(
                              left: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  '대표',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text('닉네임 (2~8자, 한글/영문/숫자)', style: _labelStyle),
              const SizedBox(height: 8),
              TextField(
                controller: _nicknameController,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                enableSuggestions: true,
                autocorrect: true,
                maxLength: 8,
                decoration: const InputDecoration(
                  hintText: '닉네임을 입력하세요',
                  filled: true,
                  fillColor: Colors.white,
                  border: _inputBorder,
                  enabledBorder: _inputBorder,
                  focusedBorder: _inputBorder,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              const Text('성별', style: _labelStyle),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: _inputBorder,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('남성')),
                  DropdownMenuItem(value: 'female', child: Text('여성')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _gender = value);
                },
              ),
              const SizedBox(height: 16),
              const Text('선호 성별', style: _labelStyle),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _preferredGender,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: _inputBorder,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(value: 'opposite', child: Text('이성 선호')),
                  DropdownMenuItem(value: 'male', child: Text('남성')),
                  DropdownMenuItem(value: 'female', child: Text('여성')),
                  DropdownMenuItem(value: 'all', child: Text('무관')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _preferredGender = value);
                },
              ),
              const SizedBox(height: 16),
              const Text('소속 대학교', style: _labelStyle),
              const SizedBox(height: 8),
              InkWell(
                onTap: _isEditing
                    ? null
                    : () async {
                        final chosen = await showModalBottomSheet<String>(
                          context: context,
                          isScrollControlled: true,
                          builder: (ctx) => _SchoolPickerSheet(
                            schoolList: _schoolList,
                            current: _affiliation,
                          ),
                        );
                        if (chosen != null && mounted) setState(() => _affiliation = chosen);
                      },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: _inputBorder,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    suffixIcon: Icon(LucideIcons.chevronDown, size: 20),
                  ),
                  child: Text(
                    _schoolListLoaded ? _affiliation : '로딩 중...',
                    style: TextStyle(
                      color: _schoolListLoaded ? Colors.black87 : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('키 (150~195cm)', style: _labelStyle),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final v = await showModalBottomSheet<int>(
                    context: context,
                    builder: (ctx) => _HeightPicker(initial: _heightCm ?? 170),
                  );
                  if (v != null) setState(() { _heightCm = v; _heightController.text = v.toString(); });
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    hintText: '탭하여 선택',
                    filled: true,
                    fillColor: Colors.white,
                    border: _inputBorder,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: Text(_heightCm != null ? '$_heightCm cm' : '탭하여 선택'),
                ),
              ),
              const SizedBox(height: 16),
              const Text('한 줄 소개 (최대 40자)', style: _labelStyle),
              const SizedBox(height: 8),
              TextField(
                controller: _introOneLineController,
                maxLength: 40,
                maxLines: 1,
                decoration: const InputDecoration(
                  hintText: '자신을 소개해주세요',
                  filled: true,
                  fillColor: Colors.white,
                  border: _inputBorder,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              const Text('학번', style: _labelStyle),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _gradeYear,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: _inputBorder,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: List.generate(6, (i) => DropdownMenuItem(
                  value: _gradeYearValues[i],
                  child: Text(_gradeYearOptions[i]),
                )),
                onChanged: (v) => setState(() => _gradeYear = v),
              ),
              const SizedBox(height: 16),
              const Text('MBTI', style: _labelStyle),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _mbtiOptions.contains(_mbtiController.text.trim()) ? _mbtiController.text.trim() : null,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: _inputBorder,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: _mbtiOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) { if (v != null) setState(() => _mbtiController.text = v); },
              ),
              const SizedBox(height: 16),
              const Text('나를 소개하는 태그', style: _labelStyle),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _idealKeywordOptions.map((label) {
                  final selected = _idealTypeKeywords.contains(label);
                  final canSelect = selected || _idealTypeKeywords.length < 3;
                  return FilterChip(
                    label: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? Colors.white : const Color(0xFF374151))),
                    selected: selected,
                    selectedColor: const Color(0xFFF43F5E),
                    checkmarkColor: Colors.white,
                    side: BorderSide(color: selected ? const Color(0xFFF43F5E) : const Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    onSelected: canSelect
                        ? (v) {
                            setState(() {
                              if (v == true) {
                                if (_idealTypeKeywords.length < 3) _idealTypeKeywords.add(label);
                              } else {
                                _idealTypeKeywords.remove(label);
                              }
                            });
                          }
                        : null,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('평소 패션 스타일', style: _labelStyle),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _fashionStyle,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: _inputBorder,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: _fashionOptions.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (v) => setState(() => _fashionStyle = v),
              ),
              const SizedBox(height: 16),
              const Text('선호 데이트 유형', style: _labelStyle),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _preferredDateType,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: _inputBorder,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: _dateTypeOptions.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (v) => setState(() => _preferredDateType = v),
              ),
              const SizedBox(height: 16),
              const Text('활동 시간대', style: _labelStyle),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _activityTime,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: _inputBorder,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: _activityTimeOptions.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (v) => setState(() => _activityTime = v),
              ),
              const SizedBox(height: 16),
              const Text('요즘 빠진 것 (최대 20자)', style: _labelStyle),
              const SizedBox(height: 8),
              TextField(
                controller: _intoLatelyController,
                maxLength: 20,
                maxLines: 1,
                decoration: const InputDecoration(
                  hintText: '요즘 관심사를 알려주세요',
                  filled: true,
                  fillColor: Colors.white,
                  border: _inputBorder,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              const Text('흡연 여부', style: _labelStyle),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _smoking,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: _inputBorder,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(value: 'none', child: Text('비흡연')),
                  DropdownMenuItem(value: 'sometimes', child: Text('가끔')),
                  DropdownMenuItem(value: 'often', child: Text('자주')),
                ],
                onChanged: (value) => setState(() => _smoking = value),
              ),
              const SizedBox(height: 16),
              const Text('음주 여부', style: _labelStyle),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _drinking,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: _inputBorder,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(value: 'none', child: Text('안 함')),
                  DropdownMenuItem(value: 'sometimes', child: Text('가끔')),
                  DropdownMenuItem(value: 'often', child: Text('자주')),
                ],
                onChanged: (value) => setState(() => _drinking = value),
              ),
              const SizedBox(height: 16),
              const Text('이상형', style: _labelStyle),
              const SizedBox(height: 8),
              TextField(
                controller: _idealTypeController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: '이상형을 입력하세요',
                  filled: true,
                  fillColor: Colors.white,
                  border: _inputBorder,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text('학과', style: _labelStyle),
              const SizedBox(height: 8),
              TextField(
                controller: _departmentController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: '학과를 입력하세요',
                  filled: true,
                  fillColor: Colors.white,
                  border: _inputBorder,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 24),
              Material(
                elevation: 4,
                shadowColor: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: _isLoading ? null : _submit,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFFF43F5E), Color(0xFFEC4899)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: const Color(0xFFF43F5E).withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: _isLoading
                        ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                        : Text(
                            _isEditing ? '프로필 수정' : '프로필 저장',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_result.isNotEmpty) Text(_result, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
        ],
      ),
    );
  }
}

class _HeightPicker extends StatefulWidget {
  final int initial;

  const _HeightPicker({required this.initial});

  @override
  State<_HeightPicker> createState() => _HeightPickerState();
}

class _HeightPickerState extends State<_HeightPicker> {
  late int _value;
  late FixedExtentScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _value = widget.initial.clamp(150, 195);
    _scrollController = FixedExtentScrollController(initialItem: _value - 150);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: 280,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(_value),
                  child: const Text('완료'),
                ),
              ],
            ),
            Expanded(
              child: ListWheelScrollView.useDelegate(
                controller: _scrollController,
                itemExtent: 44,
                diameterRatio: 1.2,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (i) => setState(() => _value = 150 + i),
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: 46,
                  builder: (context, index) {
                    final cm = 150 + index;
                    return Center(
                      child: Text(
                        '$cm cm',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: cm == _value ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 학교 검색 + 가나다순 리스트 선택 시트
class _SchoolPickerSheet extends StatefulWidget {
  const _SchoolPickerSheet({
    required this.schoolList,
    required this.current,
  });

  final List<String> schoolList;
  final String current;

  @override
  State<_SchoolPickerSheet> createState() => _SchoolPickerSheetState();
}

class _SchoolPickerSheetState extends State<_SchoolPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filtered {
    if (_query.trim().isEmpty) return widget.schoolList;
    final q = _query.trim().toLowerCase();
    return widget.schoolList
        .where((name) => name.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: '학교 검색',
                    prefixIcon: const Icon(LucideIcons.search, size: 22),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  autofocus: true,
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? Center(
                        child: Text(
                          _query.trim().isEmpty ? '학교 목록이 없어요' : '검색 결과가 없어요',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: list.length,
                        itemBuilder: (context, i) {
                          final name = list[i];
                          final selected = name == widget.current;
                          return ListTile(
                            title: Text(name),
                            trailing: selected ? Icon(LucideIcons.check, size: 20, color: Theme.of(context).colorScheme.primary) : null,
                            onTap: () => Navigator.of(context).pop(name),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
