import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/shared/theme/nearo_theme.dart';
import 'package:nearo_app/shared/widgets/primary_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  int _currentPage = 0;
  late AnimationController _shakeController;
  bool _isTransitioning = false;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      icon: Icons.favorite_border,
      title: '보이는 것 없이도\n설렘은 시작돼요',
      description: '가볍게 시작하고,\n대화로 천천히 알아가요.',
    ),
    _OnboardingPage(
      icon: Icons.auto_awesome_outlined,
      title: '궁금함이\n설렘이 되는 순간',
      description: '열어볼지 말지 선택하는 재미.\n추측하고, 확인하는 과정도 즐겨보세요.',
    ),
    _OnboardingPage(
      icon: Icons.people_outline,
      title: '서로 준비됐을 때\n자연스럽게',
      description: '충분히 알아간 뒤,\n서로 원할 때만 다음 단계로 이어져요.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _goToLogin() {
    Navigator.of(context).pushNamed(AppRoutes.login);
  }

  /// 물이 잔잔하게 흔들리는 느낌의 오프셋 (sin 곡선으로 부드럽게)
  double _waveOffset(double t) {
    const amp = 4.0;
    const cycles = 2.5;
    return math.sin(t * math.pi * cycles) * amp * (1 - t);
  }

  void _onUnderstandTap() async {
    if (_isTransitioning) return;
    _isTransitioning = true;

    // 1. 물이 잔잔하게 흔들리는 효과
    _shakeController.forward(from: 0);
    await _shakeController.forward();
    _shakeController.reset();

    if (!mounted) return;
    if (_currentPage == _pages.length - 1) {
      _goToLogin();
      _isTransitioning = false;
      return;
    }

    // 2. 다음 페이지로 (AnimatedSwitcher가 화면이 바뀌는 전환 처리)
    setState(() => _currentPage++);
    _isTransitioning = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'MeetZy',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  TextButton(
                    onPressed: _goToLogin,
                    child: const Text('건너뛰기'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: _shakeController,
                builder: (context, _) {
                  final shake = _shakeController.isAnimating
                      ? _waveOffset(_shakeController.value)
                      : 0.0;
                  return Transform.translate(
                    offset: Offset(shake, shake * 0.25),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.12),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            )),
                            child: child,
                          ),
                        );
                      },
                      child: Padding(
                        key: ValueKey<int>(_currentPage),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: NearoTheme.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(32),
                              ),
                              child: Icon(
                                _pages[_currentPage].icon,
                                size: 56,
                                color: NearoTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              _pages[_currentPage].title,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _pages[_currentPage].description,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? NearoTheme.primary
                          : NearoTheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: PrimaryButton(
                label: _currentPage == _pages.length - 1 ? '시작하기' : '이해했어요',
                onPressed: () {
                  if (!_isTransitioning) _onUnderstandTap();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });
}
