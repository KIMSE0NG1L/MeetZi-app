import 'package:flutter/material.dart';
import 'package:nearo_app/shared/theme/nearo_theme.dart';

/// Design 폴더 SplashScreen 스타일: 로고, MeetZi 그라데이션 텍스트, 로딩 스피너.: 로고, MeetZi 그라데이션 텍스트, 로딩 스피너.
/// 앱에서 최소 3.3초 표시 후 initialRoute로 전환.
/// 핑크색은 Design colorThemes.ts pink 그대로 사용.
class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  /// Design colorThemes.ts pink: gradient (rose-300 via pink-300 to rose-400)
  static const _pinkGradient = NearoTheme.designPinkGradient;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 390, maxHeight: 844),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(48),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 24,
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(48),
            child: Stack(
              children: [
                // White background
                const Positioned.fill(child: ColoredBox(color: Colors.white)),

                // Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),

                      // Logo + glow
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: child,
                          );
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Pulsing glow
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                final scale =
                                    1.0 + 0.15 * _pulseController.value;
                                final opacity =
                                    0.15 + 0.1 * _pulseController.value;
                                return Transform.scale(
                                  scale: scale,
                                  child: Container(
                                    width: 160,
                                    height: 160,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: NearoTheme.designPink500
                                              .withOpacity(opacity),
                                          blurRadius: 40,
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Logo placeholder (앱 아이콘 또는 AssetImage 사용 가능)
                            Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: _pinkGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: NearoTheme.designPink500.withOpacity(0.3),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.favorite_rounded,
                                size: 80,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // MeetZi gradient text
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.9, end: 1),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: child,
                          );
                        },
                        child: ShaderMask(
                          shaderCallback: (bounds) => _pinkGradient
                              .createShader(bounds),
                          child: const Text(
                            'MeetZi',
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1.5,
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Loading spinner
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 96),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
