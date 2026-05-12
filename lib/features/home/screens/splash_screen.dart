import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

/// 스플래시: 이미지 디자인 — 흰 배경, 가운데 앱 아이콘(icon.png), MeetZi 그라데이션 텍스트, 하단 핑크 로딩 인디케이터.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _spinnerOpacity;
  Timer? _completeTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _logoScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.5, curve: Curves.easeOut),
      ),
    );
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
      ),
    );
    _spinnerOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
      ),
    );
    _controller.forward();

    _completeTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _completeTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// 이미지: 하단 핑크/마젠타 로딩 인디케이터
  static const _spinnerColor = Color(0xFFEC4899); // pink-500
  static const _spinnerTrackColor = Color(0xFFFBCFE8); // pink-200

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Directionality(
        textDirection: TextDirection.ltr,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              return CustomSingleChildLayout(
                delegate: _CenterDelegate(),
                child: SizedBox(
                  width: 280,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 가운데 로고 = 앱 아이콘 (assets/icon.png)
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _logoOpacity.value,
                            child: Transform.scale(
                              scale: _logoScale.value,
                              child: child,
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 40),
                          child: SizedBox(
                            width: 160,
                            height: 160,
                            child: Image.asset(
                              'assets/icon.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: const Icon(Icons.favorite, size: 64, color: Colors.grey),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      // MeetZi 텍스트 — 핑크→퍼플 그라데이션 (FittedBox로 작은 화면 대응)
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _textOpacity.value,
                            child: ShaderMask(
                              blendMode: BlendMode.srcIn,
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Color(0xFFEC4899),
                                  Color(0xFFA855F7),
                                  Color(0xFFDB2777),
                                ],
                              ).createShader(bounds),
                              child: child,
                            ),
                          );
                        },
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: const Text(
                              'MeetZi',
                              style: TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                                decoration: TextDecoration.none,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 하단 핑크 로딩 스피너
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _spinnerOpacity.value,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 48, bottom: 24),
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: const AlwaysStoppedAnimation<Color>(_spinnerColor),
                                  backgroundColor: _spinnerTrackColor,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 화면 정중앙에 자식 배치 (픽셀 단위)
class _CenterDelegate extends SingleChildLayoutDelegate {
  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return Offset(
      (size.width - childSize.width) / 2,
      (size.height - childSize.height) / 2,
    );
  }

  @override
  bool shouldRelayout(covariant SingleChildLayoutDelegate oldDelegate) => false;
}
