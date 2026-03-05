import 'package:flutter/material.dart';
import 'package:nearo_app/shared/theme/nearo_theme.dart';

/// MeetZi 스플래시: 흰 배경, 로고 이미지(assets/icon.png), MeetZi 텍스트, 하단 로딩 스피너.
/// 이미지 로드 실패 시 해당 영역에 실패 문구와 디버그 로그를 표시함.
class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  /// 스플래시 로고 경로. 아래 순서로 있으면 사용됨: icon.png → images/logo.png
  static const _splashLogoPath = 'assets/icon.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // 로고 + MeetZi → 전체 영역을 채운 뒤 그 안에서 정중앙
            Positioned.fill(
              child: Center(
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: Center(
                          child: Image.asset(
                            _splashLogoPath,
                            width: 140,
                            height: 140,
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                            errorBuilder: (context, error, stackTrace) {
                              final errStr = error?.toString() ?? 'unknown';
                              final stackStr = stackTrace?.toString().split('\n').take(3).join('\n') ?? '';
                              return Container(
                                width: 140,
                                height: 140,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  border: Border.all(color: Colors.red.shade200),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '이미지 로드 실패',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red.shade800,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text('path: $_splashLogoPath', style: const TextStyle(fontSize: 10)),
                                      const SizedBox(height: 2),
                                      Text('error: $errStr', style: const TextStyle(fontSize: 9), maxLines: 2, overflow: TextOverflow.ellipsis),
                                      if (stackStr.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text('stack: $stackStr', style: const TextStyle(fontSize: 8), maxLines: 3, overflow: TextOverflow.ellipsis),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Meet',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                              color: NearoTheme.designPink500,
                              letterSpacing: -1.2,
                            ),
                          ),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                NearoTheme.designPink500,
                                Color(0xFF8B5CF6),
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              'Zi',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            ),
            // 스피너는 하단 고정
            Positioned(
              left: 0,
              right: 0,
              bottom: 48,
              child: Center(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      NearoTheme.designPink500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
