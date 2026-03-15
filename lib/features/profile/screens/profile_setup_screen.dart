import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/core/theme/university_theme.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';
import 'package:nearo_app/features/auth/data/environment_status_repository.dart';
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
  final _environmentStatusRepository = EnvironmentStatusRepository();
  static const int _introMinLength = 20;
  static const int _introMaxLength = 100;
  static const int _textMinLength = 10;
  static const int _textMaxLength = 100;
  static const int _maxTagCount = 10;
  final _nicknameController = TextEditingController();
  final _idealTypeController = TextEditingController();
  final _departmentController = TextEditingController();
  String _affiliation = '';
  bool _affiliationLoaded = false;
  final _heightController = TextEditingController();
  final _introOneLineController = TextEditingController();
  final _intoLatelyController = TextEditingController();
  String _gender = 'male';
  String _preferredGender = 'opposite';
  bool? _isSmoking;
  bool? _isDrinking;
  String? _gradeYear;
  List<String> _idealTypeKeywords = [];
  String? _fashionStyle;
  String? _preferredDateType;
  String? _activityTime;
  int? _heightCm; // 120~200 스크롤용
  String? _avatarSeed;
  String? _avatarStyle;
  Map<String, String> _avatarOptions = {};
  bool _isLoading = false;
  String _result = '';
  bool _isEditing = false;
  bool _forceEdit = false;
  bool _isInitialSetup = false;
  bool _didReadArgs = false;
  XFile? _selectedPhoto;
  List<dynamic> _photos = [];
  bool _isUploadingPhoto = false;
  String? _photoError;
  String _boardDisplayType = 'avatar'; // avatar | photo — 게시판에 아바타 vs 본인 사진
  // MBTI 세그먼트 버튼용 (각 차원별 선택, null이면 미선택)
  String? _mbtiEI; // E / I
  String? _mbtiNS; // N / S
  String? _mbtiFT; // F / T
  String? _mbtiPJ; // P / J

  bool get _hasAvatarConfigured =>
      _avatarSeed != null && _avatarSeed!.trim().isNotEmpty;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadArgs) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is bool) {
      _forceEdit = args;
    } else if (args is Map) {
      _isInitialSetup = args['isInitialSetup'] == true;
    }
    _didReadArgs = true;
    _loadProfileIfExists();
    _loadVerifiedAffiliation();
  }

  Future<void> _loadVerifiedAffiliation() async {
    try {
      final status = await _environmentStatusRepository.getMyEnvironmentStatus();
      final environment = status['environment'];
      final name = environment is Map ? environment['name']?.toString() : null;
      if (!mounted) return;
      setState(() {
        if (name != null && name.isNotEmpty) _affiliation = name;
        _affiliationLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _affiliationLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _heightController.dispose();
    _idealTypeController.dispose();
    _departmentController.dispose();
    _introOneLineController.dispose();
    _intoLatelyController.dispose();
    super.dispose();
  }

  static const List<MapEntry<String, List<String>>> _idealKeywordGroups = [
    MapEntry('1. 성격 (Personality)', [
      '귀여운',
      '다정한',
      '장난기 많은',
      '차분한',
      '긍정적인',
      '낙천적인',
      '여유로운',
      '침착한',
      '따뜻한',
      '감성적인',
      '현실적인',
      '솔직한',
    ]),
    MapEntry('2. 사고방식 / 가치관 (Mindset)', [
      '지적인',
      '논리적인',
      '철학적인',
      '생각이 깊은',
      '호기심 많은',
      '도전적인',
      '열정적인',
      '계획적인',
      '즉흥적인',
      '미래지향적인',
      '창의적인',
      '아이디어 많은',
      '새로운 거 좋아하는',
    ]),
    MapEntry('3. 인간관계 / 사회성 (Social)', [
      '외향적인',
      '내향적인',
      '사람 좋아하는',
      '친구 많은',
      '대화 좋아하는',
      '경청 잘하는',
      '공감 잘하는',
      '배려심 있는',
    ]),
    MapEntry('4. 신뢰 / 성숙함 (Reliability)', [
      '책임감 있는',
      '리더십 있는',
      '자기관리 잘하는',
      '성실한',
      '독립적인',
      '자기주도적인',
      '신뢰감 있는',
      '듬직한',
    ]),
    MapEntry('5. 매력 / 분위기 (Charm)', [
      '유머감각 있는',
      '장난 좋아하는',
      '귀여운 매력 있는',
      '반전 매력 있는',
      '카리스마 있는',
      '감정 표현 잘하는',
      '조용히 챙겨주는',
    ]),
    MapEntry('6. 라이프스타일 (Lifestyle)', [
      '운동 좋아하는',
      '패션 감각 있는',
      '집돌이/집순이',
    ]),
    MapEntry('7. 취미 / 활동 (Hobby)', [
      '여행 좋아하는',
      '맛집 탐방 좋아하는',
      '카페 좋아하는',
      '영화 좋아하는',
      '음악 좋아하는',
      '산책 좋아하는',
      '드라이브 좋아하는',
      '게임 좋아하는',
      '책 읽는 거 좋아하는',
      '자기계발 좋아하는',
    ]),
  ];
  static const List<String> _gradeYearOptions = ['1', '2', '3', '4', '5', '졸업유예'];
  static const List<String> _gradeYearValues = ['one', 'two', 'three', 'four', 'five', 'graduation_deferred'];
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
    MapEntry('night_owl', '야행성'),
  ];
  String _keywordDisplayLabel(String label) {
    if (label == '집돌이/집순이') return '집돌이 / 집순이';
    return label;
  }

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
      // smoking/drinking: boolean 필드 우선, 없으면 legacy 문자열에서 변환
      final isSmoking = user['isSmoking'];
      final isDrinking = user['isDrinking'];
      if (isSmoking != null) _isSmoking = isSmoking == true;
      if (isDrinking != null) _isDrinking = isDrinking == true;
      if (_isSmoking == null) {
        final smoking = user['smoking']?.toString();
        if (smoking != null) _isSmoking = smoking != 'none';
      }
      if (_isDrinking == null) {
        final drinking = user['drinking']?.toString();
        if (drinking != null) _isDrinking = drinking != 'none';
      }
      final mbti = user['mbti']?.toString();
      if (mbti != null && mbti.length == 4) {
        _mbtiEI = mbti[0];
        _mbtiNS = mbti[1];
        _mbtiFT = mbti[2];
        _mbtiPJ = mbti[3];
      }

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
      final boardDisplay = user['boardDisplayType']?.toString();
      if (boardDisplay == 'photo' || boardDisplay == 'avatar') _boardDisplayType = boardDisplay!;

      final hasExistingProfile = nickname != null && nickname.isNotEmpty;

      setState(() {
        _isEditing = _forceEdit || (!_isInitialSetup && hasExistingProfile);
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

  Future<void> _deletePhoto(String photoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('사진 삭제'),
        content: const Text('이 사진을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('삭제', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _photoError = null);
    try {
      await _photoRepository.deletePhoto(photoId: photoId);
      if (!mounted) return;
      await _loadPhotos();
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() => _photoError = error.response?.data?.toString() ?? '삭제에 실패했습니다.');
    }
  }

  String _resolvePhotoUrl(String storageKey) {
    if (storageKey.startsWith('http')) return storageKey;
    if (storageKey.startsWith('/')) return '${AppConfig.baseUrl}$storageKey';
    return '${AppConfig.baseUrl}/$storageKey';
  }

  void _showPhotoLarge({String? imageUrl, File? file}) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      barrierDismissible: true,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: GestureDetector(
            onTap: () {},
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(LucideIcons.x, color: Colors.white, size: 28),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width - 48,
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(LucideIcons.imageOff, size: 80, color: Colors.white54),
                            )
                          : file != null
                              ? Image.file(file, fit: BoxFit.contain)
                              : const SizedBox.shrink(),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  '탭하면 닫기',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _boardDisplayChip({required String label, required String value, required IconData icon}) {
    final selected = _boardDisplayType == value;
    return Material(
      color: selected ? Theme.of(context).colorScheme.primary.withOpacity(0.12) : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () async {
          if (_boardDisplayType == value) return;
          final prev = _boardDisplayType;
          setState(() => _boardDisplayType = value);
          try {
            await _repository.setBoardDisplayType(value);
          } catch (_) {
            if (mounted) setState(() => _boardDisplayType = prev);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade600),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w500, color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade700)),
            ],
          ),
        ),
      ),
    );
  }

  /// 닉네임: 2~8자, 한글/영문/숫자만, 특수문자·공백 불가
  static bool _isValidNickname(String s) {
    final t = s.trim();
    if (t.length < 2 || t.length > 8) return false;
    return RegExp(r'^[가-힣a-zA-Z0-9]+$').hasMatch(t);
  }

  Future<void> _submit() async {
    final nickname = _nicknameController.text.trim();
    final intro = _introOneLineController.text.trim();
    final hobby = _intoLatelyController.text.trim();
    final idealType = _idealTypeController.text.trim();
    if (nickname.isEmpty) {
      setState(() => _result = '닉네임을 입력해 주세요.');
      return;
    }
    if (!_isValidNickname(nickname)) {
      setState(() => _result = '닉네임은 2~8자, 한글/영문/숫자만 가능하며 특수문자·공백은 불가합니다.');
      return;
    }

    final heightCm = _heightCm ?? int.tryParse(_heightController.text.trim());
    if (heightCm == null) {
      setState(() => _result = '키를 반드시 입력해 주세요.');
      return;
    }
    if (heightCm < 120 || heightCm > 200) {
      setState(() => _result = '키는 120~200cm 범위로 입력해 주세요.');
      return;
    }
    if (_affiliation.trim().isEmpty) {
      setState(() => _result = '인증된 학교 정보를 확인한 뒤 다시 시도해 주세요.');
      return;
    }
    if (intro.length < _introMinLength || intro.length > _introMaxLength) {
      setState(() => _result = '자기 소개는 20자 이상 100자 이하로 입력해 주세요.');
      return;
    }
    if (hobby.length < _textMinLength || hobby.length > _textMaxLength) {
      setState(() => _result = '취미는 10자 이상 100자 이하로 입력해 주세요.');
      return;
    }
    if (idealType.length < _textMinLength || idealType.length > _textMaxLength) {
      setState(() => _result = '이상형은 10자 이상 100자 이하로 입력해 주세요.');
      return;
    }
    if (_gradeYear == null) {
      setState(() => _result = '학년을 선택해 주세요.');
      return;
    }
    if (_mbtiEI == null || _mbtiNS == null || _mbtiFT == null || _mbtiPJ == null) {
      setState(() => _result = 'MBTI를 모두 선택해 주세요.');
      return;
    }
    if (_idealTypeKeywords.isEmpty) {
      setState(() => _result = '나를 소개하는 태그를 1개 이상 선택해 주세요.');
      return;
    }
    if (_fashionStyle == null || _preferredDateType == null || _activityTime == null || _isSmoking == null || _isDrinking == null) {
      setState(() => _result = '취향과 라이프스타일 항목을 모두 선택해 주세요.');
      return;
    }
    if (_idealTypeKeywords.length > _maxTagCount) {
      setState(() => _result = '나를 소개하는 태그는 최대 10개까지 선택할 수 있어요.');
      return;
    }

    if (!_hasAvatarConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('\uC544\uBC14\uD0C0\uB97C \uBA3C\uC800 \uC124\uC815\uD574\uC8FC\uC138\uC694.'),
        ),
      );
      await Navigator.of(context).pushNamed(AppRoutes.avatarSetup);
      if (!mounted) return;
      await _loadProfileIfExists();
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
        if (!_isEditing) 'gender': _gender,
        'affiliationText': _affiliation,
        'heightCm': heightCm,
        'isSmoking': _isSmoking,
        'isDrinking': _isDrinking,
        'mbti': '$_mbtiEI$_mbtiNS$_mbtiFT$_mbtiPJ',
        'idealType': idealType,
        'preferredGenders': preferredGenders,
        'gradeYear': _gradeYear,
        'introOneLine': intro,
        'idealTypeKeywords': _idealTypeKeywords,
        'fashionStyle': _fashionStyle,
        'preferredDateType': _preferredDateType,
        'activityTime': _activityTime,
        'intoLately': hobby,
      });
      _applyThemeForAffiliation();
      if (!mounted) return;
      if (_isInitialSetup || _isEditing) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.home,
          (route) => false,
        );
        return;
      }
      setState(() => _result = response.toString());
      if (!mounted) return;
      Navigator.of(context).pushNamed(AppRoutes.environment);
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
      if (mounted) setState(() => _isLoading = false);
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

  /// ad ProfileEditScreen: 항상 그라데이션 헤더 (프로필 생성 / 프로필 수정 / 프로필 등록)
  Widget _buildAppDesignHeader(BuildContext context, Color surface, Color onSurface) {
    final topInset = MediaQuery.of(context).padding.top;
    final pt = topInset > 0 ? topInset : 56.0;
    final title = _isInitialSetup ? '프로필 생성' : (_isEditing ? '프로필 수정' : '프로필 등록');
    return Container(
        padding: EdgeInsets.only(left: 12, right: 20, top: pt, bottom: 20),
        decoration: BoxDecoration(
          gradient: ThemeController.getHeaderGradient(),
          boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 4, offset: Offset(0, 2))],
        ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                if (_isInitialSetup) {
                  Navigator.of(context).pushReplacementNamed(AppRoutes.emailVerification);
                } else {
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 24),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 48),
          ],
        ),
          if (_isInitialSetup) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.3)),
                        child: const Icon(LucideIcons.check, color: Colors.white, size: 20),
                      ),
                      const SizedBox(height: 8),
                      Text('메일 인증', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.8))),
                    ],
                  ),
                ),
                Expanded(flex: 2, child: Container(height: 2, color: Colors.white.withValues(alpha: 0.3))),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Icon(LucideIcons.user, size: 20, color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(height: 8),
                      const Text('프로필', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
                Expanded(flex: 2, child: Container(height: 2, color: Colors.white.withValues(alpha: 0.3))),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.3)),
                        child: Icon(LucideIcons.check, size: 20, color: Colors.white.withValues(alpha: 0.6)),
                      ),
                      const SizedBox(height: 8),
                      Text('완료', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.8))),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 스크린샷 스타일: 한 열 = 위 라벨 + 위 버튼 + 아래 버튼 + 아래 라벨 (E/I, N/S, F/T, P/J)
  Widget _buildMbtiColumn(
    BuildContext context, {
    required String topLabel,
    required String bottomLabel,
    required String topLetter,
    required String bottomLetter,
    required void Function(String?) onSelect,
    required String? current,
    Color? surface,
    Color? onSurface,
    Color? borderColor,
  }) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final bg = surface ?? (dark ? const Color(0xFF374151) : const Color(0xFFF3F4F6));
    final fg = onSurface ?? (dark ? const Color(0xFFE5E7EB) : const Color(0xFF374151));
    final border = borderColor ?? (dark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB));
    final labelColor = dark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final primary = theme.colorScheme.primary;

    Widget letterButton(String letter) {
      final selected = current == letter;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => onSelect(letter)),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? primary.withValues(alpha: 0.15) : bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? primary : border,
                width: selected ? 2 : 1,
              ),
              boxShadow: selected ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Center(
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: selected ? primary : fg,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(topLabel, style: TextStyle(fontSize: 11, color: labelColor, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        letterButton(topLetter),
        const SizedBox(height: 6),
        letterButton(bottomLetter),
        const SizedBox(height: 6),
        Text(bottomLabel, style: TextStyle(fontSize: 11, color: labelColor, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildMbtiSegmentRow(
    BuildContext context,
    String left,
    String right,
    void Function(String?) onSelect,
    String? current,
    Color surface,
    Color onSurface,
    Color borderColor,
  ) {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => onSelect(left)),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: current == left ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15) : surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: current == left ? Theme.of(context).colorScheme.primary : borderColor,
                    width: current == left ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    left,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: current == left ? Theme.of(context).colorScheme.primary : onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => onSelect(right)),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: current == right ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15) : surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: current == right ? Theme.of(context).colorScheme.primary : borderColor,
                    width: current == right ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    right,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: current == right ? Theme.of(context).colorScheme.primary : onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOxRow(
    BuildContext context,
    void Function(bool?) onSelect,
    bool? current,
    Color surface,
    Color onSurface,
    Color borderColor,
  ) {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => onSelect(true)),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: current == true ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15) : surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: current == true ? Theme.of(context).colorScheme.primary : borderColor,
                    width: current == true ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    'O',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: current == true ? Theme.of(context).colorScheme.primary : onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => onSelect(false)),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: current == false ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15) : surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: current == false ? Theme.of(context).colorScheme.primary : borderColor,
                    width: current == false ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    'X',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: current == false ? Theme.of(context).colorScheme.primary : onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// ad ProfileEditScreen: rounded-2xl card with icon + title
  Widget _adSectionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool dark,
    required Color cardBg,
    required Color onSurface,
    required Widget child,
  }) {
    final iconColor = dark ? const Color(0xFFF472B6) : const Color(0xFFEC4899);
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: dark ? null : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: onSurface)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF1F2937) : Colors.white;
    final onSurface = dark ? Colors.white : const Color(0xFF111827);
    final onSurfaceVariant = dark ? Colors.grey.shade400 : const Color(0xFF6B7280);
    final backgroundColor = dark ? const Color(0xFF111827) : const Color(0xFFF9FAFB);
    final borderColor = dark ? Colors.grey.shade600 : const Color(0xFFD1D5DB);
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: borderColor, width: 1),
    );
    final labelStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: onSurfaceVariant);
    final sectionLabelStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: onSurfaceVariant);

    final cardBg = dark ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.6);
    const bool useAdStyle = true; // ad 폴더 ProfileEditScreen 디자인 항상 사용
    final screenBg = useAdStyle && !dark ? null : backgroundColor;
    final screenGradient = useAdStyle && !dark
        ? ThemeController.getScreenBgGradient()
        : null;

    return Scaffold(
      backgroundColor: screenBg,
      body: Container(
        decoration: BoxDecoration(
          color: screenBg,
          gradient: screenGradient,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAppDesignHeader(context, surface, onSurface),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    if (_isInitialSetup) ...[
                      Text(
                        '나를 소개해주세요 ✨',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: onSurface),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '매력적인 프로필로 특별한 인연을 만나보세요',
                        style: TextStyle(fontSize: 14, color: onSurfaceVariant),
                      ),
                      const SizedBox(height: 24),
                    ],
                    _adSectionCard(
                      context: context,
                      icon: LucideIcons.camera,
                      title: '프로필 이미지',
                      dark: dark,
                      cardBg: cardBg,
                      onSurface: onSurface,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('아바타', style: TextStyle(fontSize: 12, color: onSurfaceVariant)),
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
                                          diceBearAvatarUrl(_avatarSeed!, options: _avatarOptions.isNotEmpty ? _avatarOptions : null),
                                          fit: BoxFit.cover,
                                          placeholderBuilder: (context) => const Center(child: CircularProgressIndicator()),
                                        ),
                                      )
                                    : Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: dark ? Colors.grey.shade700 : Colors.grey.shade200,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(LucideIcons.user, size: 40, color: onSurfaceVariant),
                                      ),
                              ),
                              const SizedBox(width: 12),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: borderColor, width: 1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text('아바타 편집', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: onSurface)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('프로필 사진', style: TextStyle(fontSize: 12, color: onSurfaceVariant)),
                          const SizedBox(height: 8),
                            Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (_selectedPhoto != null) {
                                    _showPhotoLarge(file: File(_selectedPhoto!.path));
                                  }
                                },
                                child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: dark ? Colors.grey.shade700 : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: _selectedPhoto == null
                                    ? Icon(LucideIcons.upload, size: 32, color: onSurfaceVariant)
                                    : Image.file(
                                        File(_selectedPhoto!.path),
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              ),
                              const SizedBox(width: 12),
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
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: borderColor, width: 1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(_photos.isEmpty ? '사진 선택' : '다른 사진 선택', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: onSurface)),
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
                                            gradient: ThemeController.getHeaderGradient(),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
                                          ),
                                          child: _isUploadingPhoto
                                              ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                                              : Text(_photos.isEmpty ? '사진 업로드' : '사진 변경', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
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
                      final photoId = photo['id']?.toString() ?? '';
                      final storageKey = photo['storageKey']?.toString() ?? '';
                      final isPrimary = photo['isPrimary'] == true;
                      return Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (storageKey.isNotEmpty) _showPhotoLarge(imageUrl: _resolvePhotoUrl(storageKey));
                            },
                            child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: dark ? Colors.grey.shade800 : Colors.grey.shade100,
                              border: Border.all(
                                color: isPrimary
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: storageKey.isEmpty
                                ? Icon(LucideIcons.imageOff, color: onSurfaceVariant)
                                : Image.network(
                                    _resolvePhotoUrl(storageKey),
                                    fit: BoxFit.cover,
                                  ),
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
                          if (photoId.isNotEmpty)
                            Positioned(
                              right: 4,
                              top: 4,
                              child: Material(
                                color: Colors.black54,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  onTap: () => _deletePhoto(photoId),
                                  customBorder: const CircleBorder(),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(LucideIcons.x, size: 16, color: Colors.white),
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
                          Text('프로필 방식', style: labelStyle),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _boardDisplayChip(
                                  label: '아바타',
                                  value: 'avatar',
                                  icon: LucideIcons.smile,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _boardDisplayChip(
                                  label: '내 사진',
                                  value: 'photo',
                                  icon: LucideIcons.image,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _adSectionCard(
                      context: context,
                      icon: LucideIcons.user,
                      title: '기본 정보',
                      dark: dark,
                      cardBg: cardBg,
                      onSurface: onSurface,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('닉네임 (2~8자, 한글/영문/숫자)', style: labelStyle),
                          const SizedBox(height: 8),
                          TextField(
                controller: _nicknameController,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                enableSuggestions: true,
                autocorrect: true,
                maxLength: 8,
                style: TextStyle(color: onSurface),
                decoration: InputDecoration(
                  hintText: '닉네임을 입력하세요',
                  hintStyle: TextStyle(color: onSurfaceVariant),
                  filled: true,
                  fillColor: surface,
                  border: inputBorder,
                  enabledBorder: inputBorder,
                  focusedBorder: inputBorder,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              Text('성별', style: labelStyle),
              const SizedBox(height: 8),
              _isEditing
                  ? InputDecorator(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: surface,
                        border: inputBorder,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        suffixIcon: Icon(LucideIcons.lock, size: 20, color: onSurfaceVariant),
                      ),
                      child: Text(
                        _gender == 'male' ? '남성' : '여성',
                        style: TextStyle(color: onSurface),
                      ),
                    )
                  : DropdownButtonFormField<String>(
                value: _gender,
                dropdownColor: surface,
                icon: const SizedBox.shrink(),
                style: TextStyle(color: onSurface),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: surface,
                  border: inputBorder,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: [
                  DropdownMenuItem(value: 'male', child: Text('남성', style: TextStyle(color: onSurface))),
                  DropdownMenuItem(value: 'female', child: Text('여성', style: TextStyle(color: onSurface))),
                ],
                onChanged: (value) {
                        if (value == null) return;
                        setState(() => _gender = value);
                      },
              ),
              const SizedBox(height: 16),
              Text('소속 대학교', style: labelStyle),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '대학교 인증에서 선택한 학교로 자동 고정됩니다.',
                  style: TextStyle(fontSize: 12, color: onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 8),
              InputDecorator(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: surface,
                  border: inputBorder,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  suffixIcon: Icon(LucideIcons.lock, size: 20, color: onSurfaceVariant),
                ),
                child: Text(
                  _affiliationLoaded
                      ? (_affiliation.isNotEmpty ? _affiliation : '인증된 학교 정보를 불러오지 못했습니다')
                      : '로딩 중...',
                  style: TextStyle(
                    color: _affiliationLoaded && _affiliation.isNotEmpty ? onSurface : onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('키', style: labelStyle),
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
                  decoration: InputDecoration(
                    hintText: '탭하여 선택',
                    hintStyle: TextStyle(color: onSurfaceVariant),
                    filled: true,
                    fillColor: surface,
                    border: inputBorder,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: Text(
                    _heightCm != null ? '$_heightCm cm' : '탭하여 선택',
                    style: TextStyle(color: _heightCm != null ? onSurface : onSurfaceVariant),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('학년', style: labelStyle),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _gradeYear,
                dropdownColor: surface,
                style: TextStyle(color: onSurface),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: surface,
                  border: inputBorder,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: List.generate(6, (i) => DropdownMenuItem(
                  value: _gradeYearValues[i],
                  child: Text(_gradeYearOptions[i], style: TextStyle(color: onSurface)),
                )),
                onChanged: (v) => setState(() => _gradeYear = v),
              ),
              const SizedBox(height: 16),
              Text('MBTI', style: labelStyle),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMbtiColumn(
                      context,
                      topLabel: '외향',
                      bottomLabel: '내향',
                      topLetter: 'E',
                      bottomLetter: 'I',
                      onSelect: (v) => _mbtiEI = v,
                      current: _mbtiEI,
                      surface: surface,
                      onSurface: onSurface,
                      borderColor: borderColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMbtiColumn(
                      context,
                      topLabel: '직관',
                      bottomLabel: '현실',
                      topLetter: 'N',
                      bottomLetter: 'S',
                      onSelect: (v) => _mbtiNS = v,
                      current: _mbtiNS,
                      surface: surface,
                      onSurface: onSurface,
                      borderColor: borderColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMbtiColumn(
                      context,
                      topLabel: '감성',
                      bottomLabel: '이성',
                      topLetter: 'F',
                      bottomLetter: 'T',
                      onSelect: (v) => _mbtiFT = v,
                      current: _mbtiFT,
                      surface: surface,
                      onSurface: onSurface,
                      borderColor: borderColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMbtiColumn(
                      context,
                      topLabel: '탐색',
                      bottomLabel: '계획',
                      topLetter: 'P',
                      bottomLetter: 'J',
                      onSelect: (v) => _mbtiPJ = v,
                      current: _mbtiPJ,
                      surface: surface,
                      onSurface: onSurface,
                      borderColor: borderColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('자기 소개 (20자 이상)', style: labelStyle),
              const SizedBox(height: 8),
              TextField(
                controller: _introOneLineController,
                maxLength: 100,
                maxLines: 3,
                style: TextStyle(color: onSurface),
                decoration: InputDecoration(
                  hintText: '나를 소개하는 글을 20자 이상 작성해 주세요',
                  hintStyle: TextStyle(color: onSurfaceVariant),
                  filled: true,
                  fillColor: surface,
                  border: inputBorder,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
                        ],
                      ),
                    ),
                    _adSectionCard(
                      context: context,
                      icon: LucideIcons.sparkles,
                      title: '나를 소개하는 태그',
                      dark: dark,
                      cardBg: cardBg,
                      onSurface: onSurface,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('나를 잘 표현하는 태그를 선택해보세요 (최대 10개)', style: TextStyle(fontSize: 12, color: onSurfaceVariant)),
                          const SizedBox(height: 8),
                          ..._idealKeywordGroups.map((group) {
                            final sectionTitle = group.key;
                            final labels = group.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sectionTitle,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 2,
                                    children: labels.map((label) {
                                      final selected = _idealTypeKeywords.contains(label);
                                      final primary = Theme.of(context).colorScheme.primary;
                                      return FilterChip(
                                        label: Text(
                                          _keywordDisplayLabel(label),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: selected ? Colors.white : onSurface,
                                          ),
                                        ),
                                        selected: selected,
                                        selectedColor: primary,
                                        checkmarkColor: Colors.white,
                                        visualDensity: const VisualDensity(horizontal: -2, vertical: -3),
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                                        side: BorderSide(color: selected ? primary : borderColor),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                                        onSelected: (v) {
                                          setState(() {
                                            if (v == true) {
                                              if (_idealTypeKeywords.length < _maxTagCount) {
                                                _idealTypeKeywords.add(label);
                                              }
                                            } else {
                                              _idealTypeKeywords.remove(label);
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    _adSectionCard(
                      context: context,
                      icon: LucideIcons.heart,
                      title: '취향 & 라이프스타일',
                      dark: dark,
                      cardBg: cardBg,
                      onSurface: onSurface,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('평소 패션 스타일', style: labelStyle),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _fashionStyle,
                dropdownColor: surface,
                style: TextStyle(color: onSurface),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: surface,
                  border: inputBorder,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: _fashionOptions.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: TextStyle(color: onSurface)))).toList(),
                onChanged: (v) => setState(() => _fashionStyle = v),
              ),
              const SizedBox(height: 16),
              Text('선호 데이트 유형', style: labelStyle),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _preferredDateType,
                dropdownColor: surface,
                style: TextStyle(color: onSurface),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: surface,
                  border: inputBorder,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: _dateTypeOptions.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: TextStyle(color: onSurface)))).toList(),
                onChanged: (v) => setState(() => _preferredDateType = v),
              ),
              const SizedBox(height: 16),
              Text('활동 시간대', style: labelStyle),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _activityTime,
                dropdownColor: surface,
                style: TextStyle(color: onSurface),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: surface,
                  border: inputBorder,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: _activityTimeOptions.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: TextStyle(color: onSurface)))).toList(),
                onChanged: (v) => setState(() => _activityTime = v),
              ),
              const SizedBox(height: 16),
              Text('흡연 여부', style: labelStyle),
              const SizedBox(height: 8),
              _buildOxRow(context, (v) => _isSmoking = v, _isSmoking, surface, onSurface, borderColor),
              const SizedBox(height: 16),
              Text('음주 여부', style: labelStyle),
              const SizedBox(height: 8),
              _buildOxRow(context, (v) => _isDrinking = v, _isDrinking, surface, onSurface, borderColor),
              const SizedBox(height: 16),
              Text('취미 (10자 이상)', style: labelStyle),
              const SizedBox(height: 8),
              TextField(
                controller: _intoLatelyController,
                maxLength: 100,
                maxLines: 3,
                style: TextStyle(color: onSurface),
                decoration: InputDecoration(
                  hintText: '취미를 10자 이상 적어 주세요',
                  hintStyle: TextStyle(color: onSurfaceVariant),
                  filled: true,
                  fillColor: surface,
                  border: inputBorder,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              Text('이상형 (10자 이상)', style: labelStyle),
              const SizedBox(height: 8),
              TextField(
                controller: _idealTypeController,
                textInputAction: TextInputAction.next,
                maxLength: 100,
                maxLines: 3,
                style: TextStyle(color: onSurface),
                decoration: InputDecoration(
                  hintText: '이상형을 10자 이상 적어 주세요',
                  hintStyle: TextStyle(color: onSurfaceVariant),
                  filled: true,
                  fillColor: surface,
                  border: inputBorder,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
                        ],
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
                            gradient: ThemeController.getHeaderGradient(),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: ThemeController.seedColor.value.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: _isLoading
                              ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                              : Text(
                                  _isInitialSetup
                                      ? '완료하고 시작하기 🎉'
                                      : _isEditing
                                          ? '프로필 수정'
                                          : '프로필 저장',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_result.isNotEmpty) Text(_result, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                ),
              ),
            ),
          ],
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
    _value = widget.initial.clamp(120, 200);
    _scrollController = FixedExtentScrollController(initialItem: _value - 120);
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
                onSelectedItemChanged: (i) => setState(() => _value = 120 + i),
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: 81,
                  builder: (context, index) {
                    final cm = 120 + index;
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
