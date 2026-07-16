import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/features/settings/data/notice_repository.dart';
import 'package:nearo_app/features/settings/screens/event_tab_content.dart';

class NoticeListScreen extends StatefulWidget {
  const NoticeListScreen({super.key});

  @override
  State<NoticeListScreen> createState() => _NoticeListScreenState();
}

class _NoticeListScreenState extends State<NoticeListScreen>
    with SingleTickerProviderStateMixin {
  String _selectedFilter = '공지';
  final List<String> _filters = ['공지', '업데이트'];

  final Map<String, String> _typeMap = {
    '공지': 'notice',
    '이벤트': 'event',
    '업데이트': 'update',
  };

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFB4005D);
    const bgColor = Color(0xFFFFF4F7);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFFFF4D94)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _tabController.index == 0 ? 'Event' : 'Notice',
          style: const TextStyle(
            color: Color(0xFFFF4D94),
            fontWeight: FontWeight.bold,
            fontFamily: 'PlusJakartaSans',
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(
            children: [
              Container(color: const Color(0xFFFFECF3), height: 1),
              TabBar(
                controller: _tabController,
                indicatorColor: primaryColor,
                indicatorWeight: 3,
                labelColor: primaryColor,
                unselectedLabelColor: const Color(0xFFD4A0B8),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  fontFamily: 'PlusJakartaSans',
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
                tabs: const [
                  Tab(text: '이벤트'),
                  Tab(text: '공지사항'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 탭1: 이벤트 (출석체크 + 친구초대)
          const EventTabContent(),
          // 탭2: 공지사항 리스트
          _buildNoticeTab(),
        ],
      ),
    );
  }

  Widget _buildNoticeTab() {
    const primaryColor = Color(0xFFB4005D);
    const primaryContainer = Color(0xFFFF6FA2);
    const onSurfaceVariant = Color(0xFF7B4D67);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: NoticeRepository().getNotices(),
      builder: (context, snapshot) {
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Hero Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primaryColor, primaryContainer],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'CAMPUS FESTIVAL NEWS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'MeetZi 공지사항',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'PlusJakartaSans',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '캠퍼스의 즐거운 소식을 가장 먼저 확인하세요!',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        bottom: -10,
                        right: 0,
                        child: Icon(
                          LucideIcons.partyPopper,
                          size: 48,
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Filter Tabs
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: _filters.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedFilter = filter),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryColor : const Color(0xFFFFECF3),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : null,
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              color: isSelected ? Colors.white : onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Notice List
            if (snapshot.connectionState == ConnectionState.waiting)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: primaryColor)),
              )
            else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.megaphone, size: 64, color: onSurfaceVariant.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      const Text('등록된 공지사항이 없습니다.', style: TextStyle(color: onSurfaceVariant)),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final notice = snapshot.data![index];
                      final fullDate = notice['createdAt']?.toString() ?? '';
                      final date = fullDate.length >= 10 ? fullDate.substring(0, 10).replaceAll('-', '.') : fullDate;
                      final title = notice['title'] ?? '제목 없음';

                      // DB 타입 필드 기반 필터링
                      final noticeType = notice['type']?.toString() ?? 'notice';
                      if (_selectedFilter != '전체' && noticeType != _typeMap[_selectedFilter]) {
                        return const SizedBox.shrink();
                      }

                      return _buildStyledNoticeItem(
                        context,
                        date: date,
                        title: title,
                        isNew: index == 0, // 첫번째 항목만 NEW로 표시 (또는 서버 createdAt 비교)
                        content: notice['content'] ?? '',
                        type: noticeType,
                      );
                    },
                    childCount: snapshot.data!.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildStyledNoticeItem(
    BuildContext context, {
    required String date,
    required String title,
    required String content,
    required String type,
    bool isNew = false,
  }) {
    const onSurface = Color(0xFF482139);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: onSurface.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NoticeDetailScreen(
                  title: title,
                  date: date,
                  content: content,
                  type: type,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isNew)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6FA2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'PlusJakartaSans',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: const TextStyle(
                          color: Color(0xFF7B4D67),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight, color: Color(0xFFD49DBA), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NoticeDetailScreen extends StatelessWidget {
  final String title;
  final String date;
  final String content;
  final String type;

  const NoticeDetailScreen({
    super.key,
    required this.title,
    required this.date,
    required this.content,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFB4005D);
    const primaryContainer = Color(0xFFFF6FA2);
    const bgColor = Color(0xFFFFF4F7);
    const onSurface = Color(0xFF482139);
    const onSurfaceVariant = Color(0xFF7B4D67);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFFFF4D94)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Notice',
          style: TextStyle(
            color: Color(0xFFFF4D94),
            fontWeight: FontWeight.bold,
            fontFamily: 'PlusJakartaSans',
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // Header Section: Gradient Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryColor, primaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -10,
                    right: -10,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Text(
                          type == 'event' ? '이벤트' : type == 'update' ? '업데이트' : '공지',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'PlusJakartaSans',
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Icon(LucideIcons.calendar, color: Colors.white.withOpacity(0.8), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            date,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Content Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: onSurface.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.8,
                      color: onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(color: Color(0xFFFFECF3)),
                  const SizedBox(height: 16),
                  Text(
                    'MeetZi는 여러분의 피드백을 소중하게 생각합니다. 불편한 점이 있다면 언제든지 고객센터로 문의해 주세요.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Back to List Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(LucideIcons.list, size: 20),
                label: const Text(
                  '목록으로 돌아가기',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  backgroundColor: Colors.white,
                  side: BorderSide(color: primaryColor.withOpacity(0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
