import 'package:nearo_app/shared/api/api_client.dart';
import 'package:nearo_app/shared/api/endpoints.dart';

class ReportRepository {
  ReportRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// 상대방 신고 → 서버에서 DB 저장 후 지원 이메일로 전송
  Future<void> report({
    required String matchId,
    required String reason,
    String? detail,
  }) async {
    await _client.dio.post(
      '/report',
      data: {
        'matchId': matchId,
        'reason': reason,
        if (detail != null && detail.isNotEmpty) 'detail': detail,
      },
    );
  }

  /// 커뮤니티 글 신고 (로그인 필요)
  Future<void> reportCommunityPost({
    required String postId,
    required String reason,
    String? detail,
  }) async {
    await _client.dio.post(
      ApiEndpoints.reportCommunityPost,
      data: {
        'postId': postId,
        'reason': reason,
        if (detail != null && detail.isNotEmpty) 'detail': detail,
      },
    );
  }
}
