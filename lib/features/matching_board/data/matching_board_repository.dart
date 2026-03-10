import 'package:dio/dio.dart';
import 'package:nearo_app/shared/api/api_client.dart';

/// 설명 주석
/// 설명 주석
class MyTickets {
  const MyTickets({
    required this.viewTicket,
    required this.matchingTicket,
    required this.registerTicket,
  });
  final int viewTicket;
  final int matchingTicket;
  final int registerTicket;
}

class MySummary {
  const MySummary({
    required this.user,
    required this.tickets,
  });

  final Map<String, dynamic> user;
  final MyTickets tickets;
}

class MatchingBoardRepository {
  final ApiClient _client;

  MatchingBoardRepository({ApiClient? client}) : _client = client ?? ApiClient();
  static String _dioMessage(DioException e, {String fallback = '요청 처리 중 오류가 발생했습니다.'}) {
    final data = e.response?.data;
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) return message.trim();
      if (message is List && message.isNotEmpty) {
        final joined = message.map((m) => m.toString().trim()).where((m) => m.isNotEmpty).join('\\n');
        if (joined.isNotEmpty) return joined;
      }
      final error = data['error'];
      if (error is String && error.trim().isNotEmpty) return error.trim();
    } else if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }
    return e.message?.trim().isNotEmpty == true ? e.message!.trim() : fallback;
  }

  /// 설명 주석
  Future<List<Map<String, dynamic>>> fetchProfiles({String? preferredGender}) async {
    final query = <String, dynamic>{};
    if (preferredGender != null && preferredGender.isNotEmpty) {
      query['gender'] = preferredGender;
    }
    final response = await _client.dio.get('/matching-board', queryParameters: query);
    final rawList = response.data;
    if (rawList is! List) return [];
    final list = <Map<String, dynamic>>[];
    for (final e in rawList) {
      if (e is! Map) continue;
      list.add(_normalizeBoardProfile(Map<String, dynamic>.from(e as Map)));
    }
    return list;
  }

  /// 설명 주석
  static Map<String, dynamic> _normalizeBoardProfile(Map<String, dynamic> p) {
    final user = p['user'] is Map ? p['user'] as Map<String, dynamic> : null;
    final out = Map<String, dynamic>.from(p);
    if (out['nickname'] == null || out['nickname'].toString().trim().isEmpty) {
      final n = user?['nickname']?.toString().trim();
      if (n != null && n.isNotEmpty) out['nickname'] = n;
    }
    if (out['userId'] == null && user != null) {
      final id = user['id']?.toString();
      if (id != null) out['userId'] = id;
    }
    if (out['idealType'] == null || out['idealType'].toString().trim().isEmpty) {
      final t = user?['idealType']?.toString().trim();
      if (t != null && t.isNotEmpty) out['idealType'] = t;
    }
    return out;
  }

  Future<void> registerProfile(Map<String, dynamic> profile) async {
    try {
      await _client.dio.post(
        '/matching-board/register',
        data: profile,
        options: Options(sendTimeout: const Duration(seconds: 25), receiveTimeout: const Duration(seconds: 25)),
      );
    } on DioException catch (e) {
      throw _dioMessage(e, fallback: '매칭 요청 중 오류가 발생했습니다.');
    }
  }

  /// 설명 주석
  /// 설명 주석
  Future<void> takeNote(String profileId, {String? message}) async {
    final body = <String, dynamic>{'profileId': profileId};
    if (message != null && message.trim().isNotEmpty) body['message'] = message.trim();
    try {
      await _client.dio.post(
        '/matching-board/take-note',
        data: body,
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
    } on DioException catch (e) {
      throw _dioMessage(e, fallback: '등록 중 오류가 발생했습니다.');
    }
  }

  /// 설명 주석
  Future<List<Map<String, dynamic>>> fetchMyTakeNoteRequests() async {
    final response = await _client.dio.get('/matching-board/take-note-requests');
    final list = response.data;
    if (list is! List) return [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// 설명 주석
  Future<List<Map<String, dynamic>>> fetchMySentTakeNoteRequests() async {
    final response = await _client.dio.get('/matching-board/take-note-requests/sent');
    final list = response.data;
    if (list is! List) return [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// 설명 주석
  Future<Map<String, dynamic>> fetchTakeNoteRequest(String requestId) async {
    final response = await _client.dio.get('/matching-board/take-note-requests/$requestId');
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 설명 주석
  Future<void> acceptTakeNoteRequest(String requestId) async {
    await _client.dio.post('/matching-board/take-note-requests/$requestId/accept');
  }

  /// 설명 주석
  Future<void> rejectTakeNoteRequest(String requestId, String rejectionMessage) async {
    await _client.dio.post(
      '/matching-board/take-note-requests/$requestId/reject',
      data: {'message': rejectionMessage.trim()},
    );
  }

  /// 설명 주석
  Future<void> consumeViewTicket(String profileId) async {
    await _client.dio.post('/matching-board/consume-view-ticket', data: {'profileId': profileId});
  }

  /// 설명 주석
  Future<MyTickets> fetchMyTickets() async {
    try {
      final response = await _client.dio.get('/users/me/tickets');
      final data = response.data as Map<String, dynamic>;
      return MyTickets(
        viewTicket: (data['viewTicket'] as num?)?.toInt() ?? 0,
        matchingTicket: (data['matchingTicket'] as num?)?.toInt() ?? 0,
        registerTicket: (data['registerTicket'] as num?)?.toInt() ?? 0,
      );
    } on DioException catch (_) {
      return const MyTickets(viewTicket: 0, matchingTicket: 0, registerTicket: 0);
    }
  }

  /// GET /users/me/summary -> { user, tickets }
  Future<MySummary> fetchMySummary() async {
    final response = await _client.dio.get('/users/me/summary');
    final data = Map<String, dynamic>.from(response.data as Map);
    final user = Map<String, dynamic>.from((data['user'] as Map?) ?? const {});
    final ticketsRaw = Map<String, dynamic>.from((data['tickets'] as Map?) ?? const {});
    final tickets = MyTickets(
      viewTicket: (ticketsRaw['viewTicket'] as num?)?.toInt() ?? 0,
      matchingTicket: (ticketsRaw['matchingTicket'] as num?)?.toInt() ?? 0,
      registerTicket: (ticketsRaw['registerTicket'] as num?)?.toInt() ?? 0,
    );
    return MySummary(
      user: user,
      tickets: tickets,
    );
  }

  /// 설명 주석
  Future<void> buyMatchingTickets({int quantity = 1}) async {
    await _client.dio.post('/users/me/tickets/purchase', data: {'quantity': quantity});
  }

  /// 개발자 프로필(고정 1명) 조회: GET /matching-board/developer
  Future<Map<String, dynamic>> fetchDeveloperProfile() async {
    final response = await _client.dio.get('/matching-board/developer');
    final data = Map<String, dynamic>.from(response.data as Map);
    return _normalizeBoardProfile(data);
  }
}


