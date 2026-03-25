import 'package:nearo_app/shared/api/api_client.dart';
import 'package:nearo_app/shared/api/endpoints.dart';

class NoticeRepository {
  NoticeRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// 공지사항 목록 가져오기
  Future<List<Map<String, dynamic>>> getNotices({int limit = 50}) async {
    try {
      final res = await _client.dio.get<List>(
        ApiEndpoints.notices,
        queryParameters: {'limit': limit},
      );
      final list = res.data;
      if (list == null) return [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      // 에러 발생 시 빈 목록 반환하거나 필요 시 상위로 던짐
      return [];
    }
  }
}
