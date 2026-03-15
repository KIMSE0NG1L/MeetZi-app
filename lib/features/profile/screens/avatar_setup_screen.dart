import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';
import 'package:nearo_app/features/auth/data/environment_status_repository.dart';
import 'package:nearo_app/shared/data/lorelei_options.dart';
import 'package:nearo_app/shared/utils/dicebear_avatar.dart';
import 'package:nearo_app/shared/widgets/primary_button.dart';

/// DiceBear lorelei: 탭 + 썸네일 그리드 선택 방식으로 전면 편집
class AvatarSetupScreen extends StatefulWidget {
  const AvatarSetupScreen({super.key});

  @override
  State<AvatarSetupScreen> createState() => _AvatarSetupScreenState();
}

class _AvatarSetupScreenState extends State<AvatarSetupScreen> {
  final AuthRepository _repository = AuthRepository();
  final EnvironmentStatusRepository _environmentStatusRepository =
      EnvironmentStatusRepository();
  static const String _avatarStyle = 'lorelei';
  String _avatarSeed = '';
  Map<String, String> _avatarOptions = {};
  Map<String, String> _initialOptions = {};
  bool _loading = true;
  bool _saving = false;
  bool _hadAvatarOnOpen = false;
  String? _error;

  late List<AvatarOptionCategory> _categories;
  int _selectedTabIndex = 0;

  static String _randomSeed() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    return values.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
  }

  /// 현재 선택값만 넣은 옵션 맵 (빈 값 제외)
  Map<String, String> get _effectiveOptions {
    final m = <String, String>{};
    for (final e in _avatarOptions.entries) {
      if (e.value.isNotEmpty) m[e.key] = e.value;
    }
    return m;
  }

  bool get _isDirty {
    if (_initialOptions.length != _avatarOptions.length) return true;
    for (final e in _avatarOptions.entries) {
      if (_initialOptions[e.key] != e.value) return true;
    }
    for (final e in _initialOptions.entries) {
      if (_avatarOptions[e.key] != e.value) return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _categories = getLoreleiCategories();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    setState(() { _loading = true; _error = null; });
    try {
      final profile = await _repository.getProfile();
      final user = (profile['user'] as Map?) ?? profile;
      final seed = user['avatarSeed']?.toString();
      final optionsRaw = user['avatarOptions']?.toString();
      Map<String, String> options = {};
      if (optionsRaw != null && optionsRaw.isNotEmpty) {
        try {
          final decoded = jsonDecode(optionsRaw) as Map<dynamic, dynamic>?;
          if (decoded != null) {
            final validKeys = getLoreleiCategories().map((c) => c.apiKey).toSet();
            for (final e in decoded.entries) {
              if (e.value == null) continue;
              final key = e.key.toString();
              if (key == 'freckles') continue; // 제거된 옵션
              if (!validKeys.contains(key)) continue;
              String v = e.value.toString();
              if (e.value is List && (e.value as List).isNotEmpty) {
                v = (e.value as List).first.toString();
              }
              if (v.isNotEmpty) options[key] = v;
            }
          }
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _hadAvatarOnOpen = seed?.isNotEmpty == true;
        _avatarSeed = seed?.isNotEmpty == true ? seed! : _randomSeed();
        _avatarOptions = Map<String, String>.from(options);
        _initialOptions = Map<String, String>.from(options);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _avatarSeed = _randomSeed();
        _avatarOptions = {};
        _initialOptions = {};
        _loading = false;
        _error = '프로필을 불러오지 못했습니다.';
      });
    }
  }

  bool _isAvatarRequiredFlow() =>
      !_hadAvatarOnOpen && !Navigator.of(context).canPop();

  Future<String> _nextRouteAfterSave() async {
    try {
      final status = await _environmentStatusRepository.getMyEnvironmentStatus();
      if (status['environmentId'] == null) {
        return AppRoutes.environment;
      }
      return status['verified'] == true
          ? AppRoutes.home
          : AppRoutes.environment;
    } catch (_) {
      return AppRoutes.environment;
    }
  }

  void _randomize() {
    setState(() {
      _avatarSeed = _randomSeed();
      _error = null;
    });
  }

  void _setOption(String key, String value) {
    setState(() {
      if (value.isEmpty) {
        _avatarOptions.remove(key);
      } else {
        _avatarOptions[key] = value;
      }
    });
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    try {
      final payload = <String, dynamic>{
        'avatarStyle': _avatarStyle,
        'avatarSeed': _avatarSeed,
      };
      if (_avatarOptions.isNotEmpty) {
        payload['avatarOptions'] = jsonEncode(_avatarOptions);
      }
      await _repository.updateProfile(payload);
      if (!mounted) return;
      setState(() => _initialOptions = Map<String, String>.from(_avatarOptions));
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        return;
      }
      final route = await _nextRouteAfterSave();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '저장에 실패했습니다.';
      });
    }
  }

  Future<void> _onBack() async {
    if (_isAvatarRequiredFlow()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('\uC544\uBC14\uD0C0\uB97C \uC124\uC815\uD574\uC57C \uC571 \uC774\uC6A9\uC774 \uAC00\uB2A5\uD569\uB2C8\uB2E4.'),
        ),
      );
      return;
    }
    if (!_isDirty) {
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('변경사항이 있습니다'),
        content: const Text('저장하지 않고 나가시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('나가기')),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _onBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('아바타 편집'),
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: _onBack,
          ),
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildPreview(),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _randomize,
                      icon: const Icon(LucideIcons.shuffle, size: 18),
                      label: const Text('시드 랜덤'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTabBar(),
                    Expanded(
                      child: _buildOptionGrid(),
                    ),
                    if (_error != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                      child: SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          label: '저장하기',
                          isLoading: _saving,
                          onPressed: () => _save(),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final url = diceBearAvatarUrl(
      _avatarSeed,
      options: _effectiveOptions.isNotEmpty ? _effectiveOptions : null,
    );
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SvgPicture.network(
        url,
        fit: BoxFit.cover,
        placeholderBuilder: (context) => const Center(
          child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final selected = _selectedTabIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(cat.label, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
              selected: selected,
              onSelected: (_) => setState(() => _selectedTabIndex = index),
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
            ),
          );
        },
      ),
    );
  }

  Widget _buildOptionGrid() {
    if (_selectedTabIndex >= _categories.length) return const SizedBox.shrink();
    final category = _categories[_selectedTabIndex];
    final currentValue = _avatarOptions[category.apiKey] ?? '';

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 76,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemCount: category.options.length,
      itemBuilder: (context, index) {
        final item = category.options[index];
        final isSelected = currentValue == item.value;
        return _OptionThumbnail(
          seed: _avatarSeed,
          options: _effectiveOptions,
          categoryKey: category.apiKey,
          optionValue: item.value,
          optionLabel: item.label,
          isSelected: isSelected,
          onTap: () => _setOption(category.apiKey, item.value),
        );
      },
    );
  }
}

/// 썸네일 한 칸: 해당 옵션 적용 미리보기 + 선택 시 강조
class _OptionThumbnail extends StatelessWidget {
  const _OptionThumbnail({
    required this.seed,
    required this.options,
    required this.categoryKey,
    required this.optionValue,
    required this.optionLabel,
    required this.isSelected,
    required this.onTap,
  });

  final String seed;
  final Map<String, String> options;
  final String categoryKey;
  final String optionValue;
  final String optionLabel;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final opts = Map<String, String>.from(options);
    if (optionValue.isEmpty) {
      opts.remove(categoryKey);
    } else {
      opts[categoryKey] = optionValue;
    }
    final url = diceBearAvatarUrl(seed, options: opts.isNotEmpty ? opts : null);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.6)
                : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: SvgPicture.network(
                    url,
                    fit: BoxFit.cover,
                    placeholderBuilder: (context) => Icon(LucideIcons.user, size: 28, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                optionLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
