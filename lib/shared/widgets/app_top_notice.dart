import 'dart:async';

import 'package:flutter/material.dart';

class AppTopNotice {
  static OverlayEntry? _currentEntry;
  static Timer? _timer;

  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(milliseconds: 1600),
    IconData icon = Icons.info_rounded,
  }) {
    _timer?.cancel();
    _removeCurrent();

    final overlay = Overlay.of(context, rootOverlay: true);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    _currentEntry = OverlayEntry(
      builder: (context) => _TopNoticeOverlay(
        message: message,
        icon: icon,
        dark: dark,
      ),
    );

    overlay.insert(_currentEntry!);
    _timer = Timer(duration, _removeCurrent);
  }

  static void _removeCurrent() {
    _currentEntry?.remove();
    _currentEntry = null;
    _timer?.cancel();
    _timer = null;
  }
}

class _TopNoticeOverlay extends StatefulWidget {
  const _TopNoticeOverlay({
    required this.message,
    required this.icon,
    required this.dark,
  });

  final String message;
  final IconData icon;
  final bool dark;

  @override
  State<_TopNoticeOverlay> createState() => _TopNoticeOverlayState();
}

class _TopNoticeOverlayState extends State<_TopNoticeOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();

  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, -0.2),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 360),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: widget.dark ? const Color(0xFF111827) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: widget.dark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFE5E7EB),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.14),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(widget.icon, color: const Color(0xFFF59E0B), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            widget.message,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: widget.dark ? Colors.white : const Color(0xFF111827),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
