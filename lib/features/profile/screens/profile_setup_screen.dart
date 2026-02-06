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
import 'package:nearo_app/shared/widgets/primary_button.dart';

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
  String _affiliation = '세종대학교';
  final _heightController = TextEditingController();
  final _mbtiController = TextEditingController();
  final _instagramController = TextEditingController();
  final _bioController = TextEditingController();
  DateTime? _birthDate;
  String _gender = 'male';
  String _preferredGender = 'opposite';
  String? _smoking;
  String? _drinking;
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
    super.dispose();
  }

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

  Future<void> _submit() async {
    if (_nicknameController.text.trim().isEmpty || _birthDate == null) {
      setState(() => _result = '닉네임과 생년월일을 입력해 주세요.');
      return;
    }

    final heightCm = int.tryParse(_heightController.text.trim());

    final preferredGenders = switch (_preferredGender) {
      'male' => ['male'],
      'female' => ['female'],
      'all' => ['male', 'female'],
      _ => _gender == 'male' ? ['female'] : ['male'],
    };

    setState(() => _isLoading = true);
    try {
      final response = await _repository.updateProfile({
        'nickname': _nicknameController.text.trim(),
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
        'preferredGenders': preferredGenders,
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
      setState(() => _result = error.response?.data.toString() ?? '요청 실패');
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
                decoration: const InputDecoration(
                  labelText: '닉네임',
                  border: OutlineInputBorder(),
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
              TextField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '키 (cm)',
                  border: OutlineInputBorder(),
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
                controller: _mbtiController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'MBTI',
                  border: OutlineInputBorder(),
                ),
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
