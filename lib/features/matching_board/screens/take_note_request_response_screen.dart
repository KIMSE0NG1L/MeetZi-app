import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/features/matching_board/data/matching_board_repository.dart';
import 'package:nearo_app/features/matching_board/screens/matching_board_screen.dart' as board;
import 'package:nearo_app/shared/utils/dicebear_avatar.dart';
import 'package:nearo_app/shared/utils/photo_url.dart';

/// ?곷?媛 ?섏뿉寃?蹂대궦 媛?멸?湲??붿껌 ?곸꽭 ?붾㈃.
/// ?섎씫 ??留ㅼ묶 ?깆궗, 嫄곗젅 ??嫄곗젅 ?ъ쑀瑜??꾨떖?섍퀬 ?붿껌??留ㅼ묶沅뚯씠 ?섎텋?쒕떎.
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
  String? _senderMessage;
  bool _loading = true;
  bool _actionLoading = false;
  String? _error;

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
      final senderMessage = data['senderMessage'] as String?;
      if (!mounted) return;

      setState(() {
        _profile = requester;
        _senderMessage = senderMessage?.trim().isNotEmpty == true ? senderMessage!.trim() : null;
        _loading = false;
        _error = requester == null ? '?붿껌 ?뺣낫瑜?遺덈윭?????놁뼱??' : null;
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final dark = theme.brightness == Brightness.dark;

        return AlertDialog(
          title: const Text('?섎씫?좉퉴??'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '?섎씫?섎㈃ 留ㅼ묶???깆궗?쇱슂.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: dark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '留ㅼ묶沅?1媛쒓? ?ъ슜?⑸땲??',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('痍⑥냼'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('?섎씫'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

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

    final rejectionMessage = await showDialog<String>(
      context: context,
      builder: (_) => const _RejectMessageDialog(),
    );

    if (rejectionMessage == null || !mounted) return;

    setState(() => _actionLoading = true);
    try {
      await _repository.rejectTakeNoteRequest(widget.requestId, rejectionMessage);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('嫄곗젅?덉뼱?? ?곷? 留ㅼ묶沅뚯? ?섎텋?쇱슂.')),
      );
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

  static String _str(dynamic v) => (v?.toString().trim().isNotEmpty ?? false) ? v.toString().trim() : '-';

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
        title: const Text('媛?멸?湲??붿껌'),
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
                        Text(_error ?? '?붿껌 ?뺣낫瑜?遺덈윭?????놁뼱??', textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('?リ린'),
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
                        '?곷?媛 ?뱀떊???꾨줈?꾩쓣 媛?멸?怨??띠뼱?댁슂. 諛쏆쓣源뚯슂?',
                        style: theme.textTheme.bodyLarge?.copyWith(color: onSurfaceVariant),
                      ),
                      if (_senderMessage != null && _senderMessage!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: (dark ? Colors.white : const Color(0xFF111827)).withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('蹂대궦 硫붿떆吏', style: theme.textTheme.labelMedium?.copyWith(color: onSurfaceVariant)),
                              const SizedBox(height: 4),
                              Text(_senderMessage!, style: theme.textTheme.bodyMedium?.copyWith(color: onSurface)),
                            ],
                          ),
                        ),
                      ],
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
                              _infoRow('?숆낵', _str(_profile!['department'] ?? (_profile!['user'] as Map?)?['department']), onSurfaceVariant, onSurface),
                              _infoRow('?깅퀎', _str(_profile!['gender'] ?? (_profile!['user'] as Map?)?['gender']), onSurfaceVariant, onSurface),
                              _infoRow('?먭린 ?뚭컻', _str((_profile!['user'] as Map?)?['introOneLine']), onSurfaceVariant, onSurface),
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
                              child: const Text('嫄곗젅'),
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
                              child: _actionLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('諛쏄린'),
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
    final displayType = profile['boardDisplayType']?.toString() ?? user?['boardDisplayType']?.toString();
    final photos = user?['photos'] ?? profile['photos'];

    if (displayType == 'photo' && photos is List && photos.isNotEmpty && photos[0] is Map) {
      final key = (photos[0] as Map)['storageKey']?.toString();
      if (key != null) {
        final url = photoUrlFromStorageKey(key);
        if (url != null && url.isNotEmpty) {
          return CircleAvatar(
            radius: 44,
            backgroundColor: Colors.grey.shade200,
            child: ClipOval(
              child: Image.network(
                url,
                fit: BoxFit.cover,
                width: 88,
                height: 88,
                errorBuilder: (_, __, ___) => Icon(LucideIcons.user, size: 48, color: Colors.grey.shade600),
              ),
            ),
          );
        }
      }
    }

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
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: valueColor),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _RejectMessageDialog extends StatefulWidget {
  const _RejectMessageDialog();

  @override
  State<_RejectMessageDialog> createState() => _RejectMessageDialogState();
}

class _RejectMessageDialogState extends State<_RejectMessageDialog> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  bool get _isValid => _controller.text.trim().length >= 5;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final len = _controller.text.trim().length;
    final helperText = len > 0 && len < 5 ? '5???댁긽 ?낅젰??二쇱꽭??' : '5???댁긽 ?곸뼱 二쇱꽭?? ?붿껌?먯뿉寃??꾨떖?쇱슂.';

    return AlertDialog(
      title: const Text('嫄곗젅 ?ъ쑀'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '嫄곗젅?섎젮硫?5???댁긽 ?곸뼱 二쇱꽭?? ?붿껌?먯뿉寃??꾨떖?쇱슂.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              focusNode: _focus,
              autofocus: true,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '?? 吏湲덉? 留뚮궇 ?앷컖???놁뼱??',
                border: const OutlineInputBorder(),
                helperText: helperText,
                helperStyle: TextStyle(
                  color: len > 0 && !_isValid ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) {
                if (_isValid) Navigator.of(context).pop(_controller.text.trim());
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop<String?>(null),
          child: const Text('痍⑥냼'),
        ),
        FilledButton(
          onPressed: _isValid ? () => Navigator.of(context).pop(_controller.text.trim()) : null,
          child: const Text('嫄곗젅?섍린'),
        ),
      ],
    );
  }
}
