import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';
import 'package:nearo_app/shared/utils/dicebear_avatar.dart';
import 'package:nearo_app/shared/widgets/primary_button.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// DiceBear notionists SVG 아바타 편집: 랜덤 생성(새 seed), 미리보기, 저장
class AvatarSetupScreen extends StatefulWidget {
  const AvatarSetupScreen({super.key});

  @override
  State<AvatarSetupScreen> createState() => _AvatarSetupScreenState();
}

class _AvatarSetupScreenState extends State<AvatarSetupScreen> {
  final AuthRepository _repository = AuthRepository();
  String _avatarStyle = 'notionists';
  String _avatarSeed = '';
  bool _loading = true;
  bool _saving = false;
  String? _error;

  static String _randomSeed() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    return values.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
  }

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    setState(() { _loading = true; _error = null; });
    try {
      final profile = await _repository.getProfile();
      final user = (profile['user'] as Map?) ?? profile;
      final seed = user['avatarSeed']?.toString();
      final style = user['avatarStyle']?.toString();
      if (!mounted) return;
      setState(() {
        _avatarSeed = seed?.isNotEmpty == true ? seed! : _randomSeed();
        _avatarStyle = style ?? 'notionists';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _avatarSeed = _randomSeed();
        _avatarStyle = 'notionists';
        _loading = false;
        _error = '프로필을 불러오지 못했습니다.';
      });
    }
  }

  void _randomize() {
    setState(() {
      _avatarSeed = _randomSeed();
      _error = null;
    });
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    try {
      await _repository.updateProfile({
        'avatarStyle': _avatarStyle,
        'avatarSeed': _avatarSeed,
      });
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '저장에 실패했습니다.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('아바타 편집')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // 미리보기
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: SvgPicture.network(
                        diceBearAvatarUrl(_avatarSeed),
                        fit: BoxFit.cover,
                        placeholderBuilder: (context) => const Center(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '같은 seed면 항상 같은 아바타가 나와요.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: _randomize,
                      icon: const Icon(Icons.shuffle),
                      label: const Text('랜덤 생성'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        label: '저장하기',
                        isLoading: _saving,
                        onPressed: () { if (!_saving) _save(); },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
