import 'package:dio/dio.dart';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';
import 'package:nearo_app/features/photo/data/photo_repository.dart';
import 'package:nearo_app/shared/theme/theme_controller.dart';
import 'package:nearo_app/shared/utils/app_config.dart';
import 'package:nearo_app/shared/utils/dicebear_avatar.dart';
import 'package:nearo_app/shared/widgets/primary_button.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _repository = AuthRepository();
  final _photoRepository = PhotoRepository();
  final _nicknameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _idealTypeController = TextEditingController();
  final _departmentController = TextEditingController();
  final _favoriteFoodController = TextEditingController();
  String? _isEnrolled;
  String _affiliation = '세종대학교';
  final _heightController = TextEditingController();
  final _mbtiController = TextEditingController();
  final _instagramController = TextEditingController();
  final _bioController = TextEditingController();
  final _introOneLineController = TextEditingController();
  final _oneWordMeController = TextEditingController();
  final _intoLatelyController = TextEditingController();
  DateTime? _birthDate;
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
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _birthDateController.dispose();
    _heightController.dispose();
    _mbtiController.dispose();
    _instagramController.dispose();
    _bioController.dispose();
    _idealTypeController.dispose();
    _departmentController.dispose();
    _favoriteFoodController.dispose();
    _introOneLineController.dispose();
    _oneWordMeController.dispose();
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
      final birthYear = user['birthYear'];
      final gender = user['gender']?.toString();
      final affiliation = user['affiliationText']?.toString();

      if (nickname != null) {
        _nicknameController.text = nickname;
      }
      if (birthYear is int) {
        final birth = DateTime(birthYear, 1, 1);
        _birthDate = birth;
        _birthDateController.text = _formatDate(birth);
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
      final instagram = user['instagramHandle']?.toString();
      if (instagram != null) _instagramController.text = instagram;
      final bio = user['bio']?.toString();
      if (bio != null) _bioController.text = bio;

      final idealType = user['idealType']?.toString();
      if (idealType != null) _idealTypeController.text = idealType;
      final department = user['department']?.toString();
      if (department != null) _departmentController.text = department;
      final isEnrolled = user['isEnrolled'];
      if (isEnrolled != null) _isEnrolled = isEnrolled.toString();
      final favoriteFood = user['favoriteFood']?.toString();
      if (favoriteFood != null) _favoriteFoodController.text = favoriteFood;

      final introOneLine = user['introOneLine']?.toString();
      if (introOneLine != null) _introOneLineController.text = introOneLine;
      final oneWordMe = user['oneWordMe']?.toString();
      if (oneWordMe != null) _oneWordMeController.text = oneWordMe;
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

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _pickBirthDate() async {
    final initial = _birthDate ?? DateTime(2000, 1, 1);
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (context) {
        DateTime temp = initial;
        return SafeArea(
          child: SizedBox(
            height: 320,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(temp),
                        child: const Text('완료'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: initial,
                    maximumDate: DateTime.now(),
                    onDateTimeChanged: (value) {
                      temp = value;
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _birthDateController.text = _formatDate(picked);
      });
    }
  }

  /// 닉네임: 2~8자, 한글/영문/숫자만, 특수문자·공백 불가
  static bool _isValidNickname(String s) {
    final t = s.trim();
    if (t.length < 2 || t.length > 8) return false;
    return RegExp(r'^[가-힣a-zA-Z0-9]+$').hasMatch(t);
  }

  Future<void> _submit() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty || _birthDate == null) {
      setState(() => _result = '닉네임과 생년월일을 입력해 주세요.');
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
        'birthYear': _birthDate!.year,
        'affiliationText': _affiliation,
        if (heightCm != null) 'heightCm': heightCm,
        if (_smoking != null) 'smoking': _smoking,
        if (_drinking != null) 'drinking': _drinking,
        if (_mbtiController.text.trim().isNotEmpty)
          'mbti': _mbtiController.text.trim(),
        if (_instagramController.text.trim().isNotEmpty)
          'instagramHandle': _instagramController.text.trim(),
        if (_bioController.text.trim().isNotEmpty)
          'bio': _bioController.text.trim(),
        if (_idealTypeController.text.trim().isNotEmpty)
          'idealType': _idealTypeController.text.trim(),
        if (_departmentController.text.trim().isNotEmpty)
          'department': _departmentController.text.trim(),
        if (_isEnrolled != null)
          'isEnrolled': _isEnrolled,
        if (_favoriteFoodController.text.trim().isNotEmpty)
          'favoriteFood': _favoriteFoodController.text.trim(),
        'preferredGenders': preferredGenders,
        if (_gradeYear != null) 'gradeYear': _gradeYear,
        if (_introOneLineController.text.trim().isNotEmpty)
          'introOneLine': _introOneLineController.text.trim().length > 40
              ? _introOneLineController.text.trim().substring(0, 40)
              : _introOneLineController.text.trim(),
        if (_oneWordMeController.text.trim().isNotEmpty)
          'oneWordMe': _oneWordMeController.text.trim().length > 12
              ? _oneWordMeController.text.trim().substring(0, 12)
              : _oneWordMeController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '프로필 수정' : '프로필 등록'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              Text('아바타', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: _avatarSeed != null && _avatarSeed!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: SvgPicture.network(
                              diceBearAvatarUrl(_avatarSeed!),
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
                            child: Icon(Icons.person, size: 40, color: Colors.grey.shade600),
                          ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.of(context).pushNamed(AppRoutes.avatarSetup);
                      if (!mounted) return;
                      _loadProfileIfExists();
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('아바타 편집'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('프로필 사진', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _selectedPhoto == null
                        ? const Icon(Icons.photo, size: 40, color: Colors.grey)
                        : Image.file(
                            File(_selectedPhoto!.path),
                            fit: BoxFit.cover,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OutlinedButton(
                          onPressed: _pickPhoto,
                          child: const Text('사진 선택'),
                        ),
                        const SizedBox(height: 8),
                        PrimaryButton(
                          label: '사진 업로드',
                          isLoading: _isUploadingPhoto,
                          onPressed: _uploadSelectedPhoto,
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
                                ? const Icon(Icons.broken_image)
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
              TextField(
                controller: _nicknameController,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                enableSuggestions: true,
                autocorrect: true,
                maxLength: 8,
                decoration: const InputDecoration(
                  labelText: '닉네임 (2~8자, 한글/영문/숫자)',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _birthDateController,
                readOnly: true,
                onTap: _pickBirthDate,
                decoration: const InputDecoration(
                  labelText: '생년월일',
                  hintText: 'YYYY-MM-DD',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(
                  labelText: '성별',
                  border: OutlineInputBorder(),
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
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _preferredGender,
                decoration: const InputDecoration(
                  labelText: '선호 성별',
                  border: OutlineInputBorder(),
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
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _affiliation,
                onChanged: _isEditing
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => _affiliation = value);
                      },
                decoration: const InputDecoration(
                  labelText: '소속 대학교',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: '세종대학교', child: Text('세종대학교')),
                  DropdownMenuItem(value: '건국대학교', child: Text('건국대학교')),
                  DropdownMenuItem(value: '한양대학교', child: Text('한양대학교')),
                ],
              ),
              const SizedBox(height: 12),
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
                    labelText: '키 (150~195cm)',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(_heightCm != null ? '$_heightCm cm' : '탭하여 선택'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _introOneLineController,
                maxLength: 40,
                maxLines: 1,
                decoration: const InputDecoration(
                  labelText: '한 줄 소개 (최대 40자)',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _gradeYear,
                decoration: const InputDecoration(
                  labelText: '학년',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(6, (i) => DropdownMenuItem(
                  value: _gradeYearValues[i],
                  child: Text(_gradeYearOptions[i]),
                )),
                onChanged: (v) => setState(() => _gradeYear = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _mbtiOptions.contains(_mbtiController.text.trim()) ? _mbtiController.text.trim() : null,
                decoration: const InputDecoration(
                  labelText: 'MBTI',
                  border: OutlineInputBorder(),
                ),
                items: _mbtiOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) { if (v != null) setState(() => _mbtiController.text = v); },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _oneWordMeController,
                maxLength: 12,
                maxLines: 1,
                decoration: const InputDecoration(
                  labelText: '나를 한 단어로 (최대 12자)',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 8),
              Text('이상형 키워드 (3개 선택)', style: Theme.of(context).textTheme.bodyMedium),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _idealKeywordOptions.map((label) {
                  final selected = _idealTypeKeywords.contains(label);
                  final canSelect = selected || _idealTypeKeywords.length < 3;
                  return FilterChip(
                    label: Text(label),
                    selected: selected,
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
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _fashionStyle,
                decoration: const InputDecoration(
                  labelText: '평소 패션 스타일',
                  border: OutlineInputBorder(),
                ),
                items: _fashionOptions.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (v) => setState(() => _fashionStyle = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _preferredDateType,
                decoration: const InputDecoration(
                  labelText: '선호 데이트 유형',
                  border: OutlineInputBorder(),
                ),
                items: _dateTypeOptions.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (v) => setState(() => _preferredDateType = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _activityTime,
                decoration: const InputDecoration(
                  labelText: '활동 시간대',
                  border: OutlineInputBorder(),
                ),
                items: _activityTimeOptions.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (v) => setState(() => _activityTime = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _intoLatelyController,
                maxLength: 20,
                maxLines: 1,
                decoration: const InputDecoration(
                  labelText: '요즘 빠진 것 (최대 20자)',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _smoking,
                decoration: const InputDecoration(
                  labelText: '흡연 여부',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'none', child: Text('비흡연')),
                  DropdownMenuItem(value: 'sometimes', child: Text('가끔')),
                  DropdownMenuItem(value: 'often', child: Text('자주')),
                ],
                onChanged: (value) => setState(() => _smoking = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _drinking,
                decoration: const InputDecoration(
                  labelText: '음주 여부',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'none', child: Text('안 함')),
                  DropdownMenuItem(value: 'sometimes', child: Text('가끔')),
                  DropdownMenuItem(value: 'often', child: Text('자주')),
                ],
                onChanged: (value) => setState(() => _drinking = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _instagramController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '인스타그램 아이디',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bioController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '자기소개',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // --- 신규 프로필 항목 입력란 추가 ---
              const SizedBox(height: 12),
              TextField(
                controller: _idealTypeController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '이상형',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _departmentController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '학과',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _isEnrolled,
                decoration: const InputDecoration(
                  labelText: '재학 여부',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'true', child: Text('재학 중')),
                  DropdownMenuItem(value: 'false', child: Text('휴학/졸업')),
                ],
                onChanged: (value) => setState(() => _isEnrolled = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _favoriteFoodController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '좋아하는 음식',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: _isEditing ? '프로필 수정' : '프로필 저장',
                isLoading: _isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 16),
              Text(_result, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
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
