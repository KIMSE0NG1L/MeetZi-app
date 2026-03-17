import 'package:flutter/material.dart';
import 'package:nearo_app/features/matching_board/data/matching_board_repository.dart';
import 'package:nearo_app/features/matching_board/screens/matching_board_screen.dart';

/// 매칭/프로필 시트 열기 공통 진입점.
/// - 매칭권 로딩/전달
/// - 메시지 입력 + takeNote(message) 전달
/// - 호출처마다 누락되기 쉬운 파라미터를 한 곳에서 관리
Future<void> launchBoardNoteSheet({
  required BuildContext context,
  required MatchingBoardRepository repo,
  required Map<String, dynamic> profile,
  required Widget Function(BuildContext context, Map<String, dynamic> profile) buildAvatar,
  VoidCallback? onPop,
  bool showTertiaryCloseButton = false,
  Future<Map<String, dynamic>?> Function(List<String> excludeUserIds)? onRequestNextProfile,
}) async {
  if (!context.mounted) return;
  final tickets = await repo.fetchMyTickets();
  if (!context.mounted) return;

  await showBoardNoteSheet(
    context,
    profiles: [profile],
    startIndex: 0,
    buildAvatar: buildAvatar,
    myMatchingTicket: tickets.matchingTicket,
    onRefreshTickets: () async {
      // 각 화면에서 따로 티켓 UI 갱신이 필요하면 onPop이나 외부 상태로 처리.
      // 여기서는 시트 내부 로직(매칭 시도 가능 여부)에만 최신 티켓이 중요.
    },
    showTertiaryCloseButton: showTertiaryCloseButton,
    onPop: onPop ?? () {},
    onRequestNextProfile: onRequestNextProfile,
    onTakeNote: (profileId, _, {String? message}) async {
      await repo.takeNote(profileId, message: message);
      return true;
    },
  );
}

