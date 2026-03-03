import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/features/auth/data/environment_repository.dart';
import 'package:nearo_app/features/auth/screens/login_screen.dart';
import 'package:nearo_app/shared/theme/nearo_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingStep {
  final int id;
  final String title;
  final String description;
  final IconData? icon;
  final Color color;
  final Color bgColor;
  final bool isRanking;

  const _OnboardingStep({
    required this.id,
    required this.title,
    required this.description,
    this.icon,
    required this.color,
    required this.bgColor,
    this.isRanking = false,
  });
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  int? _previousStep; // 이전 step (exit 애니메이션용)
  late AnimationController _exitController;
  late AnimationController _enterController;
  bool _isTransitioning = false;
  List<Map<String, dynamic>> _ranking = [];
  bool _rankingLoading = true;
  final EnvironmentRepository _envRepo = EnvironmentRepository();

  /// 백엔드 실패 또는 빈 응답 시 사용할 기본 대학 랭킹
  static const List<Map<String, dynamic>> _universityRankings = [
    {'rank': 1, 'name': '서울대학교', 'users': 0},
    {'rank': 2, 'name': '연세대학교', 'users': 0},
    {'rank': 3, 'name': '고려대학교', 'users': 0},
    {'rank': 4, 'name': '카이스트', 'users': 0},
    {'rank': 5, 'name': '포스텍', 'users': 0},
  ];

  // Onboarding Flow Design의 steps 그대로
  static const List<_OnboardingStep> _steps = [
    _OnboardingStep(
      id: 1,
      title: '365일 열려있는\n우리들만의 온라인 미팅 부스',
        description: '축제의 미팅부스처럼\nMeetzi 보드에서 마음에 드는 카드를 골라보세요',
      icon: LucideIcons.clipboardList,
      color: Color(0xFFFF6B35),
      bgColor: Color(0xFFFFF8F5),
    ),
    _OnboardingStep(
      id: 2,
      title: '같은 학교 사람들과의 만남',
      description: '낯선 사람 걱정은 NO!\n 믿고 만나는 캠퍼스 커뮤니티',
      icon: Icons.school_outlined,
      color: Color(0xFF3B82F6),
      bgColor: Color(0xFFEFF6FF),
    ),
    _OnboardingStep(
      id: 3,
      title: '전국 대학생들이\n함께하고 있어요',
      description: '',
      color: Color(0xFF8B5CF6),
      bgColor: Color(0xFFFAF8FF),
      isRanking: true,
    ),
    _OnboardingStep(
      id: 4,
      title: '보드 위의 프로필이\n당신의 현실 로맨스로!',
        description: 'Meetzi가 두 분의 새로운 시작을 연결해 드립니다',
      icon: Icons.auto_awesome,
      color: NearoTheme.designPink500,
      bgColor: Color(0xFFFFF7FB),
    ),
  ];

 
  

  @override
  void initState() {
    super.initState();
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // React와 동일: 0.5초
    );
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // React와 동일: 0.5초
    );
    _loadRanking();
  }

  Future<void> _loadRanking() async {
    try {
      final list = await _envRepo.getRanking();
      if (mounted) {
        setState(() {
          _ranking = list.isNotEmpty ? list : _universityRankings;
          _rankingLoading = false;
        });
      }
    } catch (_) {
      // 백엔드 실패 시 하드코딩된 데이터 사용
      if (mounted) {
        setState(() {
          _ranking = _universityRankings;
          _rankingLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _exitController.dispose();
    _enterController.dispose();
    super.dispose();
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _handleNext() async {
    if (_isTransitioning) return;
    if (_currentStep == _steps.length - 1) {
      _goToLogin();
      return;
    }
    
    _isTransitioning = true;
    _previousStep = _currentStep;
    
    // React의 AnimatePresence mode="wait" 효과 구현
    // 1. exit 애니메이션 (현재 화면이 위로 사라짐: opacity 1->0, y: 0->-20)
    await _exitController.forward();
    
    // 2. 상태 변경
    if (mounted) {
      setState(() {
        _currentStep++;
      });
      
      // 3. enter 애니메이션 (새 화면이 아래에서 나타남: opacity 0->1, y: 20->0)
      _exitController.reset();
      _enterController.reset();
      await _enterController.forward();
      _enterController.reset();
    }
    
    _isTransitioning = false;
    _previousStep = null;
  }

  Future<void> _handlePrevious() async {
    if (_isTransitioning || _currentStep == 0) return;
    
    _isTransitioning = true;
    _previousStep = _currentStep;
    
    // React의 AnimatePresence mode="wait" 효과 구현
    // 1. exit 애니메이션 (현재 화면이 위로 사라짐: opacity 1->0, y: 0->-20)
    await _exitController.forward();
    
    // 2. 상태 변경
    if (mounted) {
      setState(() {
        _currentStep--;
      });
      
      // 3. enter 애니메이션 (이전 화면이 아래에서 나타남: opacity 0->1, y: 20->0)
      _exitController.reset();
      _enterController.reset();
      await _enterController.forward();
      _enterController.reset();
    }
    
    _isTransitioning = false;
    _previousStep = null;
  }

  @override
  Widget build(BuildContext context) {
    final currentStepData = _steps[_currentStep];
    final isLastStep = _currentStep == _steps.length - 1;

    return Scaffold(
      backgroundColor: currentStepData.bgColor, // 배경색을 단계별 색상으로
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: currentStepData.bgColor,
        child: SafeArea(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: const Cubic(0.16, 1.0, 0.3, 1.0), // ease [0.16, 1, 0.3, 1]
            color: currentStepData.bgColor,
            width: double.infinity,
            height: double.infinity,
            child: Column(
            children: [
              // 상단 인디케이터 (pt-8 px-8)
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 32, 32, 0), // pt-8 px-8
                child: Row(
                    children: [
                      // 뒤로가기 버튼 (w-8 = 32px)
                      SizedBox(
                        width: 32,
                        child: _currentStep > 0
                            ? Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _handlePrevious,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.chevron_left,
                                      color: currentStepData.color,
                                      size: 24, // w-6 h-6 = 24px
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox(),
                      ),
                      const SizedBox(width: 16), // gap-4 = 16px
                      // 인디케이터 (flex-1 flex gap-2)
                      Expanded(
                        child: Row(
                          children: List.generate(
                            _steps.length,
                            (index) => Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4), // gap-2 = 8px / 2
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  height: 6, // h-1.5 = 6px
                                  decoration: BoxDecoration(
                                    color: index <= _currentStep
                                        ? currentStepData.color
                                        : const Color(0xFFE5E7EB),
                                    borderRadius: BorderRadius.circular(3), // rounded-full
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16), // gap-4 = 16px
                      // 오른쪽 빈 공간 (대칭) (w-8 = 32px)
                      const SizedBox(width: 32),
                    ],
                  ),
              ),

              // 메인 콘텐츠 (flex-1 flex flex-col items-center justify-center px-8 py-12)
              Expanded(
                child: Stack(
                  children: [
                    // 이전 화면 (exit 애니메이션) - exit 애니메이션 중에만 표시
                    if (_previousStep != null && _exitController.isAnimating)
                      AnimatedBuilder(
                        animation: _exitController,
                        builder: (context, child) {
                          final previousStepData = _steps[_previousStep!];
                          // exit: opacity 1->0, y: 0->-20
                          return Opacity(
                            opacity: 1.0 - _exitController.value,
                            child: Transform.translate(
                              offset: Offset(0, -20 * _exitController.value),
                              child: previousStepData.isRanking
                                  ? _buildRankingPage(previousStepData)
                                  : _buildIconPage(previousStepData),
                            ),
                          );
                        },
                      ),
                    // 현재 화면 (enter 애니메이션 또는 정적 표시)
                    AnimatedBuilder(
                      animation: Listenable.merge([_exitController, _enterController]),
                      builder: (context, child) {
                        final currentStepData = _steps[_currentStep];
                        
                        // exit 애니메이션이 진행 중이면 현재 화면을 숨김
                        if (_exitController.isAnimating || _exitController.value > 0) {
                          return const SizedBox.shrink();
                        }
                        
                        // enter 애니메이션: opacity 0->1, y: 20->0
                        return Opacity(
                          opacity: _enterController.isAnimating ? _enterController.value : 1.0,
                          child: Transform.translate(
                            offset: Offset(
                              0,
                              _enterController.isAnimating ? 20 * (1.0 - _enterController.value) : 0,
                            ),
                            child: currentStepData.isRanking
                                ? _buildRankingPage(currentStepData)
                                : _buildIconPage(currentStepData),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // 하단 버튼 (px-8 pb-12)
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 48), // px-8 pb-12
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  curve: const Cubic(0.16, 1.0, 0.3, 1.0),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 15 * (1 - value)),
                        child: Material(
                          color: currentStepData.color,
                          borderRadius: BorderRadius.circular(20), // rounded-[1.25rem]
                          elevation: 8, // shadow-lg
                          child: InkWell(
                            onTap: _handleNext,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 20), // py-5 = 20px
                              alignment: Alignment.center,
                              child: Text(
                                isLastStep ? '시작하기' : '다음으로',
                                style: const TextStyle(
                                  fontSize: 18, // text-lg
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconPage(_OnboardingStep step) {
    return Padding(
      key: ValueKey('icon_${_currentStep}'),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48), // px-8 py-12
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 아이콘 (w-44 h-44 = 176px, rounded-[2.5rem] = 40px)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: const Cubic(0.16, 1.0, 0.3, 1.0), // ease [0.16, 1, 0.3, 1]
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Opacity(
                  opacity: value,
                  child: Container(
                    width: 176, // w-44 = 176px
                    height: 176, // h-44 = 176px
                    decoration: BoxDecoration(
                      color: step.color.withOpacity(0.15), // 15% opacity
                      borderRadius: BorderRadius.circular(40), // rounded-[2.5rem]
                    ),
                    child: Icon(
                      step.icon,
                      size: 80, // w-20 h-20 = 80px
                      color: step.color,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 40), // mb-10 = 40px
          // 텍스트
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: const Cubic(0.16, 1.0, 0.3, 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 15 * (1 - value)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8), // px-2
                    child: Column(
                      children: [
                        Text(
                          step.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24, // text-2xl
                            fontWeight: FontWeight.bold,
                            height: 1.3, // leading-snug
                            color: Color(0xFF111827), // text-gray-900
                          ),
                        ),
                        const SizedBox(height: 12), // mb-3 = 12px
                        Text(
                          step.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16, // text-base
                            height: 1.6, // leading-relaxed
                            color: Color(0xFF4B5563), // text-gray-600
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRankingPage(_OnboardingStep step) {
    return Padding(
      key: ValueKey('ranking_${_currentStep}'),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48), // px-8 py-12
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 타이틀 (text-center mb-8)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: const Cubic(0.16, 1.0, 0.3, 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Column(
                    children: [
                      // 아이콘 (w-20 h-20 rounded-2xl)
                      Container(
                        width: 80, // w-20 = 80px
                        height: 80, // h-20 = 80px
                        margin: const EdgeInsets.only(bottom: 16), // mb-4 = 16px
                        decoration: BoxDecoration(
                          color: step.color.withOpacity(0.2), // 20% opacity
                          borderRadius: BorderRadius.circular(16), // rounded-2xl
                        ),
                        child: Icon(
                          LucideIcons.trophy,
                          size: 48, // w-12 h-12 = 48px
                          color: step.color,
                        ),
                      ),
                      Text(
                        step.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24, // text-2xl
                          fontWeight: FontWeight.bold,
                          height: 1.3, // leading-snug
                          color: Color(0xFF111827), // text-gray-900
                        ),
                      ),
                      const SizedBox(height: 8), // mb-2 = 8px
                      const Text(
                        '실시간 활성 유저 랭킹',
                        style: TextStyle(
                          fontSize: 14, // text-sm
                          color: Color(0xFF6B7280), // text-gray-500
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32), // mb-8 = 32px
          // 랭킹 리스트 (space-y-2 max-h-[400px])
          Expanded(
            child: _rankingLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _ranking.length,
                    itemBuilder: (context, index) {
                      final item = _ranking[index];
                      final rank = item['rank'] ?? (index + 1);
                      final name = item['name']?.toString() ?? '-';
                      final users = item['users'] is int
                          ? item['users'] as int
                          : int.tryParse(item['users']?.toString() ?? '0') ?? 0;

                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 300 + (index * 50)),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(-20 * (1 - value), 0), // x: -20
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8), // space-y-2 = 8px
                                padding: const EdgeInsets.all(16), // p-4 = 16px
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16), // rounded-2xl
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05), // shadow-sm
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // 순위 (w-10 h-10 rounded-xl)
                                    Container(
                                      width: 40, // w-10 = 40px
                                      height: 40, // h-10 = 40px
                                      decoration: BoxDecoration(
                                        color: rank <= 3
                                            ? step.color.withOpacity(0.2) // 20% opacity
                                            : const Color(0xFFF3F4F6), // rankBadgeInactive
                                        borderRadius: BorderRadius.circular(12), // rounded-xl
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$rank',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18, // text-lg
                                            color: rank <= 3
                                                ? step.color
                                                : const Color(0xFF9CA3AF), // rankBadgeInactiveText
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16), // gap-4 = 16px
                                    // 대학 정보 (flex-1 min-w-0)
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF111827), // text-gray-900
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${users.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}명 활동중',
                                            style: const TextStyle(
                                              fontSize: 14, // text-sm
                                              color: Color(0xFF6B7280), // text-gray-500
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
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
