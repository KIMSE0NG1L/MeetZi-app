import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/features/matching_board/data/matching_board_repository.dart';
import 'package:nearo_app/features/matching_board/screens/matching_board_screen.dart' as board;
import 'package:nearo_app/shared/utils/dicebear_avatar.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 상대가 나한테 가져가기 요청 → 알림에서 들어와서 상세 보기 + 받기/거절 (거절 시 요청자 매칭권 환불)
class TakeNoteRequestResponseScreen extends StatefulWidget {
  const TakeNoteRequestResponseScreen({
    super.key,
    required this.requestId,
    this.requesterProfile,
  });

  final String requestId;
  final Map<String, dynamic>? requesterProfile;

  @override
  State<TakeNoteRequestResponseScreen> createState() => _TakeNoteRequestResponseScreenState();
}

class _TakeNoteRequestResponseScreenState extends State<TakeNoteRequestResponseScreen> {
  final MatchingBoardRepository _repository = MatchingBoardRepository();
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.requesterProfile != null) {
      setState(() {
        _profile = widget.requesterProfile;
        _loading = false;
      });
      return;
    }
    try {
      final data = await _repository.fetchTakeNoteRequest(widget.requestId);
      final requester = data['requester'] as Map<String, dynamic>?;
      if (!mounted) return;
      setState(() {
        _profile = requester;
        _loading = false;
        _error = requester == null ? '요청 정보를 불러올 수 없어요' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _accept() async {
    if (_actionLoading) return;
    setState(() => _actionLoading = true);
    try {
      await _repository.acceptTakeNoteRequest(widget.requestId);
      if (!mounted) return;
      await board.showMatchCompleteCelebration(context);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _reject() async {
    if (_actionLoading) return;
    setState(() => _actionLoading = true);
    try {
      await _repository.rejectTakeNoteRequest(widget.requestId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('거절했어요. 상대 매칭권은 환불돼요.')));
      Navigator.of(context).pop(false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  static String _str(dynamic v) => v?.toString() ?? '-';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF1F2937) : Colors.white;
    final onSurface = dark ? Colors.white : const Color(0xFF111827);
    final onSurfaceVariant = dark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('가져가기 요청'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || _profile == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.circleAlert, size: 48, color: theme.colorScheme.error),
                        const SizedBox(height: 16),
                        Text(_error ?? '요청 정보를 불러올 수 없어요', textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('닫기'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '누가 당신의 프로필을 가져가고 싶어해요. 받을까요?',
                        style: theme.textTheme.bodyLarge?.copyWith(color: onSurfaceVariant),
                      ),
                      const SizedBox(height: 20),
                      Material(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                        elevation: 2,
                        shadowColor: Colors.black.withOpacity(0.08),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _buildAvatar(context, _profile!),
                              const SizedBox(height: 12),
                              Text(
                                _str(_profile!['nickname']),
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: onSurface),
                              ),
                              const SizedBox(height: 16),
                              _infoRow('학과', _str(_profile!['department'] ?? (_profile!['user'] as Map?)?['department']), onSurfaceVariant, onSurface),
                              _infoRow('성별', _str(_profile!['gender'] ?? (_profile!['user'] as Map?)?['gender']), onSurfaceVariant, onSurface),
                              _infoRow('한 줄 소개', _str((_profile!['user'] as Map?)?['introOneLine']), onSurfaceVariant, onSurface),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _actionLoading ? null : _reject,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('거절'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: _actionLoading ? null : _accept,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _actionLoading ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('받기'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildAvatar(BuildContext context, Map<String, dynamic> profile) {
    final user = profile['user'] as Map<String, dynamic>?;
    final seed = user?['avatarSeed']?.toString() ?? profile['userId']?.toString();
    if (seed != null && seed.isNotEmpty) {
      return CircleAvatar(
        radius: 44,
        backgroundColor: Colors.grey.shade200,
        child: ClipOval(
          child: SvgPicture.network(
            diceBearAvatarUrl(seed),
            fit: BoxFit.cover,
            width: 88,
            height: 88,
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: 44,
      backgroundColor: Colors.grey.shade300,
      child: Icon(LucideIcons.user, size: 48, color: Colors.grey.shade600),
    );
  }

  Widget _infoRow(String label, String value, Color labelColor, Color valueColor) {
    if (value.isEmpty || value == '-') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: TextStyle(fontSize: 14, color: labelColor))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 14, color: valueColor), maxLines: 3, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
