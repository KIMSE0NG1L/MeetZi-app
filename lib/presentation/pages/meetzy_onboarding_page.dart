import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// last와 동일한 뿌리기용 고정 랜덤 값 (시드로 재현)
final _heartRand = math.Random(42);
final _heartData = List.generate(15, (i) => (
  left: _heartRand.nextDouble() * 100,
  delay: _heartRand.nextDouble() * 3,
  duration: 3.0 + _heartRand.nextDouble() * 2,
  size: 20.0 + _heartRand.nextDouble() * 20,
  xDrift: (_heartRand.nextDouble() - 0.5) * 100,
));
final _trophyRand = math.Random(43);
final _trophyData = List.generate(12, (i) => (
  left: _trophyRand.nextDouble() * 100,
  delay: _trophyRand.nextDouble() * 4,
  duration: 4.0 + _trophyRand.nextDouble() * 3,
  size: 30.0 + _trophyRand.nextDouble() * 25,
  xDrift: (_trophyRand.nextDouble() - 0.5) * 150,
  rotateEnd: (_trophyRand.nextDouble() - 0.5) * 360,
));
final _particleRand = math.Random(44);
final _particleDelays = List.generate(20, (_) => _particleRand.nextDouble() * 2);

/// last OnboardingFlow 1:1 — 4 steps, step gradient, step indicator, 다음/시작하기, 건너뛰기 + last 효과(떠다니는 하트/카드/트로피/파티클).
class MeetzyOnboardingPage extends StatefulWidget {
  const MeetzyOnboardingPage({super.key, this.onComplete});

  final VoidCallback? onComplete;

  @override
  State<MeetzyOnboardingPage> createState() => _MeetzyOnboardingPageState();
}

class _MeetzyOnboardingPageState extends State<MeetzyOnboardingPage>
    with TickerProviderStateMixin {
  static const _steps = [
    _StepData(
      title: '365일 열려있는\n우리들만의 온라인 미팅 부스',
      description: '축제의 미팅부스처럼\nMeetzi 보드에서 마음에 드는 카드를 골라보세요',
      icon: LucideIcons.clipboardList,
      gradient: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
    ),
    _StepData(
      title: '같은 학교 사람들과의 만남',
      description: '낯선 사람 걱정은 NO!\n믿고 만나는 캠퍼스 커뮤니티',
      icon: LucideIcons.school,
      gradient: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
    ),
    _StepData(
      title: '전국 대학생들이\n함께하고 있어요',
      description: '세종대 포함 전국 120개 대학교\n15,000명 이상의 학생들이 매칭 중!',
      icon: LucideIcons.trophy,
      gradient: [Color(0xFFFA8BFF), Color(0xFF2BD2FF), Color(0xFF2BFF88)],
    ),
    _StepData(
      title: '보드 위의 프로필이\n당신의 현실 로맨스로!',
      description: 'Meetzi가 두 분의 새로운 시작을 연결해 드립니다',
      icon: LucideIcons.sparkles,
      gradient: [Color(0xFFFF6B9D), Color(0xFFC06C84)],
    ),
  ];

  int _currentStep = 0;
  bool _isComplete = false;

  /// last AnimatePresence: 다음 누르면 exit(y:-20, opacity 0) → enter(y:20→0, opacity 0→1), duration 0.4
  static const _stepTransitionDuration = Duration(milliseconds: 400);
  static const _stepTransitionExitDy = 20.0;

  bool _stepExiting = false; // true면 이전 스텝이 나가고 있음
  bool _stepEntering = false; // true면 새 스텝이 들어오고 있음
  int _stepPending = 0;       // 전환 후 보여줄 스텝
  late AnimationController _stepController;

  double _elapsedSeconds = 0;
  Ticker? _ticker;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _stepController = AnimationController(
      vsync: this,
      duration: _stepTransitionDuration,
    )..addStatusListener(_onStepTransitionStatus);
    _ticker = createTicker((elapsed) {
      if (mounted) setState(() => _elapsedSeconds = elapsed.inMilliseconds / 1000);
    });
    _ticker!.start();
    _particleController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  void _onStepTransitionStatus(AnimationStatus status) {
    if (!mounted) return;
    if (status == AnimationStatus.completed) {
      if (_stepExiting) {
        setState(() {
          _currentStep = _stepPending;
          _stepExiting = false;
          _stepEntering = true;
        });
        _stepController.reset();
        _stepController.forward(); // enter 애니메이션
      } else if (_stepEntering) {
        setState(() => _stepEntering = false);
        _stepController.reset();
      }
    }
  }

  @override
  void dispose() {
    _stepController.removeStatusListener(_onStepTransitionStatus);
    _stepController.dispose();
    _ticker?.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStep < _steps.length - 1) {
      if (_stepExiting) return; // 전환 중이면 무시
      setState(() {
        _stepPending = _currentStep + 1;
        _stepExiting = true;
      });
      _stepController.forward(); // exit 애니메이션 시작
    } else {
      setState(() => _isComplete = true);
      Future.delayed(const Duration(milliseconds: 500), () {
        widget.onComplete?.call();
      });
    }
  }

  void _skip() {
    setState(() => _isComplete = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      widget.onComplete?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isComplete) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              const Text(
                '환영합니다!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '이제 모든 준비가 완료되었습니다',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withValues(alpha: 0.8),
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final step = _steps[_currentStep];
    final gradient = step.gradient.length >= 3
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: step.gradient,
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: step.gradient,
          );

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: DefaultTextStyle(
        style: const TextStyle(decoration: TextDecoration.none, decorationColor: Colors.transparent),
        child: SafeArea(
          child: Stack(
          clipBehavior: Clip.none,
          children: [
            // last 효과: 스텝별 배경 애니메이션 (터치 무시)
            if (_currentStep == 0) Positioned.fill(child: IgnorePointer(child: _FloatingHearts(elapsed: _elapsedSeconds))),
            if (_currentStep == 1) Positioned.fill(child: IgnorePointer(child: const _SwipeCards())),
            // 3페이지(step 2)는 효과 없음
            if (_currentStep == 3) Positioned.fill(child: IgnorePointer(child: _MatchingParticles(animation: _particleController))),
            Positioned(
              top: 24,
              right: 24,
              child: TextButton(
                onPressed: _skip,
                child: Text(
                  '건너뛰기',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 64, left: 24, right: 24, bottom: 24),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _stepController,
                        builder: (context, _) {
                          // last: exit opacity 0 y -20 / enter opacity 0→1 y 20→0
                          final t = _stepController.value;
                          double offsetY = 0;
                          double opacity = 1;
                          if (_stepExiting) {
                            offsetY = -_stepTransitionExitDy * t;
                            opacity = 1 - t;
                          } else if (_stepEntering) {
                            offsetY = _stepTransitionExitDy * (1 - t);
                            opacity = t;
                          }
                          final step = _steps[_currentStep];
                          return SingleChildScrollView(
                            child: Transform.translate(
                              offset: Offset(0, offsetY),
                              child: Opacity(
                                opacity: opacity.clamp(0.0, 1.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(32),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: Icon(step.icon, size: 64, color: Colors.white),
                                    ),
                                    const SizedBox(height: 48),
                                    Text(
                                      step.title,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        height: 1.3,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      step.description,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white.withValues(alpha: 0.8),
                                        height: 1.5,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_steps.length, (i) {
                      final active = i == _currentStep;
                      final past = i < _currentStep;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: active || past ? 32 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.white
                              : past
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _next,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF111827),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: Colors.black26,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentStep == _steps.length - 1 ? '시작하기' : '다음',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(LucideIcons.chevronRight, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

/// last: 떠다니는 하트 (step 0) — left%, bottom -50px, y 0→-height-100, x drift, opacity 0→1→1→0
class _FloatingHearts extends StatelessWidget {
  const _FloatingHearts({required this.elapsed});

  final double elapsed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            clipBehavior: Clip.none,
            children: List.generate(15, (i) {
              final d = _heartData[i];
              final phase = ((elapsed + d.delay) % d.duration) / d.duration;
              // last: bottom -50, y 0 → -height-100 → top = (h+50-size) - phase*(h+100)
              final top = (h + 50 - d.size) - phase * (h + 100);
              final xDrift = phase * d.xDrift;
              final left = w * (d.left / 100) + xDrift - d.size / 2;
              final rotate = phase * 360 * math.pi / 180;
              final opacity = phase < 0.2
                  ? phase / 0.2
                  : phase > 0.8
                      ? (1 - phase) / 0.2
                      : 1.0;
              return Positioned(
                left: left,
                top: top,
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Transform.rotate(
                    angle: rotate,
                    child: Icon(
                      LucideIcons.heart,
                      size: d.size,
                      color: Colors.white.withValues(alpha: 0.3),
                      fill: 0.2,
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

/// last: 스와이프 카드 (step 1) — 정적 카드만 표시 (흔들림 애니메이션 제거)
class _SwipeCards extends StatelessWidget {
  const _SwipeCards();

  static const _cardSize = Size(256.0, 320.0); // last: w-64 h-80
  static const _totalWidth = 356.0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: _totalWidth,
        height: _cardSize.height,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            _card(rot: 5, scale: 0.95, color: const Color(0xFF60A5FA).withValues(alpha: 0.4)),
            _card(rot: 0, scale: 0.98, color: const Color(0xFFA78BFA).withValues(alpha: 0.4)),
            _card(rot: -5, scale: 1, color: const Color(0xFFF472B6).withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }

  Widget _card({required double rot, required double scale, required Color color}) {
    return Transform.rotate(
      angle: rot * math.pi / 180,
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.center,
        child: Container(
          width: 256,
          height: 320,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Padding(
                padding: const EdgeInsets.only(top: 32, left: 32, right: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 8,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// last: 떠다니는 트로피 (step 2) — left%, bottom -60px, y 0→-height-120, x/rotate 랜덤, opacity 0→1→1→0
class _FloatingTrophies extends StatelessWidget {
  const _FloatingTrophies({required this.elapsed});

  final double elapsed;

  static const _icons = ['🏆', '🥇', '⭐'];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            clipBehavior: Clip.none,
            children: List.generate(12, (i) {
              final d = _trophyData[i];
              final phase = ((elapsed + d.delay) % d.duration) / d.duration;
              // last: bottom -60, y 0 → -height-120
              final top = (h + 60 - d.size) - phase * (h + 120);
              final xDrift = phase * d.xDrift;
              final left = w * (d.left / 100) + xDrift - d.size / 2;
              final rotate = phase * d.rotateEnd * math.pi / 180;
              final opacity = phase < 0.2
                  ? phase / 0.2
                  : phase > 0.8
                      ? (1 - phase) / 0.2
                      : 1.0;
              return Positioned(
                left: left,
                top: top,
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Transform.rotate(
                    angle: rotate,
                    child: Text(
                      _icons[i % 3],
                      style: TextStyle(fontSize: d.size),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

/// last: 매칭 파티클 (step 3) — 중심에서 cos/sin*200으로 퍼짐, scale/opacity [0,1,0], duration 2, delay per particle
class _MatchingParticles extends StatelessWidget {
  const _MatchingParticles({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final cx = w / 2;
        final cy = h / 2;
        return SizedBox(
          width: w,
          height: h,
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final tSec = animation.value * 2; // 0..2 sec cycle
              return Stack(
                clipBehavior: Clip.none,
                children: List.generate(20, (i) {
                  final angleDeg = (i * 360) / 20;
                  final angle = angleDeg * math.pi / 180;
                  final delay = _particleDelays[i];
                  final progress = ((tSec + delay) % 2) / 2; // 0..1
                  final r = 200.0 * progress;
                  final x = math.cos(angle) * r;
                  final y = math.sin(angle) * r;
                  final scale = progress < 0.5 ? progress * 2 : 2 - progress * 2;
                  final opacity = progress < 0.5 ? progress * 2 : 2 - progress * 2;
                  return Positioned(
                    left: cx + x - 12,
                    top: cy + y - 12,
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: scale.clamp(0.0, 1.0),
                        child: const Icon(LucideIcons.sparkles, size: 24, color: Colors.white),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        );
      },
    );
  }
}

class _StepData {
  const _StepData({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
  });
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradient;
}
