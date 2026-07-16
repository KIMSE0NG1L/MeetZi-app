import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/features/settings/data/event_repository.dart';

/// 출석체크 카드 위젯
class AttendanceCheckWidget extends StatefulWidget {
  const AttendanceCheckWidget({super.key});

  @override
  State<AttendanceCheckWidget> createState() => _AttendanceCheckWidgetState();
}

class _AttendanceCheckWidgetState extends State<AttendanceCheckWidget>
    with SingleTickerProviderStateMixin {
  final _repo = EventRepository();
  bool _loading = true;
  bool _checkedInToday = false;
  List<String> _checkedDates = [];
  int _totalThisMonth = 0;
  bool _checkingIn = false;

  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
    _loadStatus();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    try {
      final data = await _repo.getAttendanceStatus();
      if (!mounted) return;
      setState(() {
        _checkedInToday = data['checkedInToday'] == true;
        _checkedDates = List<String>.from(data['checkedDates'] ?? []);
        _totalThisMonth = data['totalThisMonth'] ?? 0;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _doCheckIn() async {
    if (_checkingIn || _checkedInToday) return;
    setState(() => _checkingIn = true);

    try {
      final data = await _repo.checkIn();
      if (!mounted) return;

      _bounceController.forward().then((_) => _bounceController.reverse());

      final reward = data['reward'] ?? 1;

      setState(() {
        _checkedInToday = true;
        _totalThisMonth += 1;
        _checkingIn = false;
      });

      if (mounted) {
        _showRewardDialog(reward);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _checkingIn = false);
        String msg = '출석 체크에 실패했습니다.';
        if (e.toString().contains('이미 출석')) {
          msg = '오늘은 이미 출석했습니다!';
          setState(() => _checkedInToday = true);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _showRewardDialog(int reward) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF4F7), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6FA2), Color(0xFFB4005D)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.check, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                '출석 완료! 🎉',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF482139),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '매칭권 $reward장이 지급되었습니다!',
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF7B4D67),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB4005D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('확인', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFFB4005D)),
        ),
      );
    }

    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF482139).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6FA2), Color(0xFFB4005D)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.calendarCheck, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${now.month}월 출석체크',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF482139),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '이번 달 ${_totalThisMonth}일',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB4005D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 달력 그리드 (이번 달)
          _buildCalendarGrid(now, daysInMonth),

          const SizedBox(height: 16),

          // 출석 버튼
          ScaleTransition(
            scale: _bounceAnimation,
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _checkedInToday ? null : _doCheckIn,
                icon: _checkingIn
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _checkedInToday ? LucideIcons.circleCheck : LucideIcons.stamp,
                        size: 20,
                      ),
                label: Text(
                  _checkedInToday ? '오늘 출석 완료!' : '출석하기 (+1 매칭권)',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _checkedInToday ? const Color(0xFFE8DEE3) : const Color(0xFFB4005D),
                  foregroundColor:
                      _checkedInToday ? const Color(0xFF7B4D67) : Colors.white,
                  disabledBackgroundColor: const Color(0xFFE8DEE3),
                  disabledForegroundColor: const Color(0xFF7B4D67),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: _checkedInToday ? 0 : 4,
                  shadowColor: const Color(0xFFB4005D).withOpacity(0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(DateTime now, int daysInMonth) {
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(daysInMonth, (i) {
        final day = i + 1;
        final dateStr =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
        final isChecked = _checkedDates.contains(dateStr);
        final isToday = dateStr == todayStr;
        final isPast = day < now.day;

        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isToday
                ? const Color(0xFFFFF0F5)
                : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: isToday
                ? Border.all(color: const Color(0xFFFF6FA2), width: 1.5)
                : Border.all(color: const Color(0xFFF1F3F5), width: 1.0),
          ),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                    color: isPast
                        ? const Color(0xFFD4C4CC)
                        : isToday
                            ? const Color(0xFFB4005D)
                            : const Color(0xFF7B4D67),
                  ),
                ),
                if (isChecked)
                  IgnorePointer(
                    child: Transform.rotate(
                      angle: -0.18,
                      child: Container(
                        width: 33,
                        height: 33,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE53935),
                            width: 1.8,
                          ),
                          color: const Color(0xFFEF5350).withOpacity(0.12),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '출석',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFE53935),
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
