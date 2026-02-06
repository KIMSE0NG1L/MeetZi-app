import 'package:nearo_app/shared/api/api_client.dart';
import 'package:nearo_app/shared/api/endpoints.dart';

class ChatRepository {
  final ApiClient _client;

  ChatRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<Map<String, dynamic>>> listRooms() async {
    final response = await _client.dio.get(ApiEndpoints.chatsRooms);
    final data = response.data;
    if (data is List) {
      return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> createRoom({required String matchId}) async {
    final response = await _client.dio.post(
      ApiEndpoints.chatsRooms,
      data: {'matchId': matchId},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> listMessages({
    required String roomId,
    DateTime? since,
  }) async {
    final response = await _client.dio.get(
      ApiEndpoints.chatsMessages(roomId),
      queryParameters: since != null ? {'since': since.toIso8601String()} : null,
    );
    final data = response.data;
    if (data is List) {
      return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> sendMessage({
    required String roomId,
    required String content,
  }) async {
    final response = await _client.dio.post(
      ApiEndpoints.chatsMessages(roomId),
      data: {'content': content},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }
}
