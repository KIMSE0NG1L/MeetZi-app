import 'package:nearo_app/shared/api/api_client.dart';
import 'package:nearo_app/shared/api/endpoints.dart';

class CommunityRepository {
  final ApiClient _client;

  CommunityRepository({ApiClient? client}) : _client = client ?? ApiClient();

  /// 학교별 커뮤니티 정보 (없으면 서버에서 생성 후 반환)
  Future<Map<String, dynamic>?> getCommunity(String environmentId) async {
    final response = await _client.dio.get(ApiEndpoints.community(environmentId));
    return response.data != null ? Map<String, dynamic>.from(response.data as Map) : null;
  }

  /// 게시글 목록 (cursor 페이지네이션)
  Future<Map<String, dynamic>> getPosts(
    String environmentId, {
    String? cursor,
    int limit = 20,
  }) async {
    final query = <String, dynamic>{'limit': limit};
    if (cursor != null && cursor.isNotEmpty) query['cursor'] = cursor;
    final response = await _client.dio.get(
      ApiEndpoints.communityPosts(environmentId),
      queryParameters: query,
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 게시글 상세 (댓글 포함)
  Future<Map<String, dynamic>?> getPost(String environmentId, String postId) async {
    final response = await _client.dio.get(
      ApiEndpoints.communityPost(environmentId, postId),
    );
    return response.data != null ? Map<String, dynamic>.from(response.data as Map) : null;
  }

  /// 게시글 작성 (로그인 필요). poll: 투표 추가 시 { question, options: [문자열 2~10개] }
  Future<Map<String, dynamic>> createPost(
    String environmentId,
    String content, {
    Map<String, dynamic>? poll,
  }) async {
    final data = <String, dynamic>{'content': content};
    if (poll != null) {
      final q = poll['question']?.toString()?.trim();
      final opts = poll['options'];
      if (q != null && q.isNotEmpty && opts is List && opts.length >= 2 && opts.length <= 10) {
        data['poll'] = {
          'question': q,
          'options': opts.map((e) => e.toString().trim()).toList(),
        };
      }
    }
    final response = await _client.dio.post(
      ApiEndpoints.communityPosts(environmentId),
      data: data,
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 댓글 작성 (로그인 필요)
  Future<Map<String, dynamic>> createComment(
    String environmentId,
    String postId,
    String content,
  ) async {
    final response = await _client.dio.post(
      ApiEndpoints.communityPostComments(environmentId, postId),
      data: {'content': content},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 좋아요 토글 (로그인 필요)
  Future<Map<String, dynamic>> toggleLike(String environmentId, String postId) async {
    final response = await _client.dio.post(
      ApiEndpoints.communityPostLike(environmentId, postId),
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 게시글 삭제 (본인 글만, 로그인 필요)
  Future<void> deletePost(String environmentId, String postId) async {
    await _client.dio.delete(ApiEndpoints.communityPostDelete(environmentId, postId));
  }

  /// 투표하기 (로그인 필요). optionIndex: 0부터 시작
  Future<Map<String, dynamic>> votePost(
    String environmentId,
    String postId,
    int optionIndex,
  ) async {
    final response = await _client.dio.post(
      ApiEndpoints.communityPostVote(environmentId, postId),
      data: {'optionIndex': optionIndex},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }
}
