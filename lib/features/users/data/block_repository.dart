import 'package:nearo_app/shared/api/api_client.dart';
import 'package:nearo_app/shared/api/endpoints.dart';

class BlockRepository {
  BlockRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// 사용자 차단
  Future<void> blockUser(String userId) async {
    await _client.dio.post(ApiEndpoints.userBlock(userId));
  }

  /// 차단 해제
  Future<void> unblockUser(String userId) async {
    await _client.dio.delete(ApiEndpoints.userBlock(userId));
  }
}
