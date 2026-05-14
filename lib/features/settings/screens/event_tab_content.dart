import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/features/settings/screens/attendance_check_screen.dart';
import 'package:nearo_app/features/settings/screens/friend_invite_screen.dart';

/// 이벤트 탭 메인 콘텐츠 — 출석체크/친구초대 네비게이션 카드
class EventTabContent extends StatelessWidget {
  const EventTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // 출석체크 카드
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _EventCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AttendanceCheckScreen()),
              ),
              gradient: const LinearGradient(
                colors: [Color(0xFFB4005D), Color(0xFFFF6FA2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              icon: LucideIcons.calendarCheck,
              title: '출석체크',
              subtitle: '매일 출석하고 무료 매칭권을 받아보세요!',
              badge: '매일 +1 매칭권',
              decorIcon: LucideIcons.stamp,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // 친구초대 카드
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _EventCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FriendInviteScreen()),
              ),
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              icon: LucideIcons.userPlus,
              title: '친구초대',
              subtitle: '친구를 초대하면 서로 매칭권을 받아요!',
              badge: '양쪽 +3 매칭권',
              decorIcon: LucideIcons.gift,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}

/// 이벤트 네비게이션 카드
class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.onTap,
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.decorIcon,
  });

  final VoidCallback onTap;
  final Gradient gradient;
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final IconData decorIcon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Stack(
              children: [
                // 배경 장식 아이콘
                Positioned(
                  bottom: -8,
                  right: -4,
                  child: Icon(
                    decorIcon,
                    size: 64,
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 배지
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // 아이콘 + 타이틀
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(icon, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'PlusJakartaSans',
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.chevronRight,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // 설명
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
