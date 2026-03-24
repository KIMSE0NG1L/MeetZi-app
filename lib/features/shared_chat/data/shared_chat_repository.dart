import 'package:nearo_app/shared/api/api_client.dart';
import 'package:nearo_app/shared/api/endpoints.dart';

class SharedChatRepository {
  final ApiClient _client;

  SharedChatRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<Map<String, dynamic>>> listMine({String? role, String? status}) async {
    final response = await _client.dio.get(
      ApiEndpoints.sharedChatMine,
      queryParameters: {
        if (role != null && role.isNotEmpty) 'role': role,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );

    final data = response.data;
    if (data is List) {
      return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> createDraft({
    required String roomId,
    required String startMessageId,
    required String endMessageId,
    required String title,
    String? summary,
  }) async {
    final response = await _client.dio.post(
      ApiEndpoints.sharedChatPosts,
      data: {
        'roomId': roomId,
        'startMessageId': startMessageId,
        'endMessageId': endMessageId,
        'title': title,
        if (summary != null && summary.trim().isNotEmpty) 'summary': summary.trim(),
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getDetail(String id) async {
    final response = await _client.dio.get(ApiEndpoints.sharedChatPost(id));
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> decideConsent(String id, String decision) async {
    final response = await _client.dio.post(
      ApiEndpoints.sharedChatConsent(id),
      data: {'decision': decision},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }
}
