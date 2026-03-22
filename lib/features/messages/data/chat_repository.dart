import 'package:nearo_app/shared/api/api_client.dart';
import 'package:nearo_app/shared/api/endpoints.dart';

class ChatRepository {
  final ApiClient _client;

  // 캐싱: API 요청 최소화
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTime = {};
  static const Duration _cacheTTL = Duration(seconds: 10);

  ChatRepository({ApiClient? client}) : _client = client ?? ApiClient();

  bool _isCacheValid(String key) {
    final time = _cacheTime[key];
    if (time == null) return false;
    return DateTime.now().difference(time).inSeconds < _cacheTTL.inSeconds;
  }

  Future<List<Map<String, dynamic>>> listRooms() async {
    const cacheKey = 'listRooms';
    if (_isCacheValid(cacheKey)) {
      return List<Map<String, dynamic>>.from(_cache[cacheKey] ?? []);
    }

    final response = await _client.dio.get(ApiEndpoints.chatsRooms);
    final data = response.data;
    final result = (data is List)
        ? data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];

    _cache[cacheKey] = result;
    _cacheTime[cacheKey] = DateTime.now();
    return result;
  }

  Future<Map<String, dynamic>> getRoom({required String roomId}) async {
    final cacheKey = 'room_$roomId';
    if (_isCacheValid(cacheKey)) {
      return Map<String, dynamic>.from(_cache[cacheKey] ?? {});
    }

    final response = await _client.dio.get(ApiEndpoints.chatsRoom(roomId));
    final result = Map<String, dynamic>.from(response.data as Map);

    _cache[cacheKey] = result;
    _cacheTime[cacheKey] = DateTime.now();
    return result;
  }

  void clearRoomCache(String roomId) {
    _cache.remove('room_$roomId');
    _cacheTime.remove('room_$roomId');
  }

  void clearAllCache() {
    _cache.clear();
    _cacheTime.clear();
  }

  Future<void> setChatRoomMute(
      {required String roomId, required bool muted}) async {
    await _client.dio
        .post(ApiEndpoints.chatsRoomMute(roomId), data: {'muted': muted});
    clearRoomCache(roomId);
    _cache.remove('listRooms');
    _cacheTime.remove('listRooms');
  }

  Future<Map<String, dynamic>> createRoom({required String matchId}) async {
    final response = await _client.dio.post(
      ApiEndpoints.chatsRooms,
      data: {'matchId': matchId},
    );
    _cache.remove('listRooms');
    _cacheTime.remove('listRooms');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> listMessages({
    required String roomId,
    DateTime? since,
    int limit = 50,
  }) async {
    final response = await _client.dio.get(
      ApiEndpoints.chatsMessages(roomId),
      queryParameters: {
        if (since != null) 'since': since.toIso8601String(),
        'limit': limit,
      },
    );
    final data = response.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
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
    clearRoomCache(roomId);
    _cache.remove('listRooms');
    _cacheTime.remove('listRooms');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> deleteRoom({required String roomId}) async {
    final response = await _client.dio.delete(ApiEndpoints.chatsRoom(roomId));
    clearRoomCache(roomId);
    _cache.remove('listRooms');
    _cacheTime.remove('listRooms');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> readMessage({
    required String roomId,
    required String messageId,
  }) async {
    final response = await _client.dio.post(
      ApiEndpoints.chatsMessageRead(roomId, messageId),
    );
    clearRoomCache(roomId);
    _cache.remove('listRooms');
    _cacheTime.remove('listRooms');
    return Map<String, dynamic>.from(response.data as Map);
  }
}
