import 'package:dio/dio.dart';
import 'package:nearo_app/shared/api/api_client.dart';

/// 怨꾩젙蹂??대엺沅?留ㅼ묶沅??깅줉沅??붾웾 (DB???щ젅?㏃쿂??蹂닿?)
/// ?깅줉沅?1???ъ슜 ??寃뚯떆???깅줉 ??留ㅼ묶沅?1??吏湲?
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
    required this.credit,
    required this.tickets,
  });

  final Map<String, dynamic> user;
  final int credit;
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

  /// 寃뚯떆???꾨줈??紐⑸줉. preferredGender: 蹂댁뿬以??곷? ?깅퀎 (?⑥옄 怨꾩젙?대㈃ 'female', ?ъ옄 怨꾩젙?대㈃ 'male')
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

  /// ?쒕쾭 ?묐떟??Profile+user ?뺥깭?щ룄 移대뱶?먯꽌 nickname/userId/idealType????긽 ?쎌쓣 ???덈룄濡?蹂닿컯
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

  /// 媛?멸?湲??붿껌 ?꾩넚 (?곷??먭쾶 ?뚮┝ 媛? ?섎씫 ?쒖뿉留?留ㅼ묶 ?깆궗 / 嫄곗젅 ??留ㅼ묶沅??섎텋)
  /// [message]: 蹂대궪 硫섑듃 (?좏깮). ?곷?諛??붿껌 ?곸꽭 ?붾㈃???쒖떆??
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

  /// ?닿? 諛쏆? 媛?멸?湲??붿껌 紐⑸줉 (留ㅼ묶?湲고븿?? pending留?
  Future<List<Map<String, dynamic>>> fetchMyTakeNoteRequests() async {
    final response = await _client.dio.get('/matching-board/take-note-requests');
    final list = response.data;
    if (list is! List) return [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// ?닿? 蹂대궦 媛?멸?湲??붿껌 紐⑸줉 (?곷?諛??쎌쓬 ?щ? ?ы븿)
  Future<List<Map<String, dynamic>>> fetchMySentTakeNoteRequests() async {
    final response = await _client.dio.get('/matching-board/take-note-requests/sent');
    final list = response.data;
    if (list is! List) return [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// 媛?멸?湲??붿껌 ?곸꽭 議고쉶 (?붿껌???꾨줈???ы븿)
  Future<Map<String, dynamic>> fetchTakeNoteRequest(String requestId) async {
    final response = await _client.dio.get('/matching-board/take-note-requests/$requestId');
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 媛?멸?湲??붿껌 ?섎씫 ??留ㅼ묶 ?깆궗
  Future<void> acceptTakeNoteRequest(String requestId) async {
    await _client.dio.post('/matching-board/take-note-requests/$requestId/accept');
  }

  /// 媛?멸?湲??붿껌 嫄곗젅 ???붿껌??留ㅼ묶沅??섎텋. [rejectionMessage] 5???댁긽 ?꾩닔.
  Future<void> rejectTakeNoteRequest(String requestId, String rejectionMessage) async {
    await _client.dio.post(
      '/matching-board/take-note-requests/$requestId/reject',
      data: {'message': rejectionMessage.trim()},
    );
  }

  /// ?대엺沅?1???뚮퉬 ???꾨줈???곸꽭 ?대엺 (移대뱶 ?????몄텧)
  Future<void> consumeViewTicket(String profileId) async {
    await _client.dio.post('/matching-board/consume-view-ticket', data: {'profileId': profileId});
  }

  /// GET /users/me/tickets ??{ viewTicket, matchingTicket, registerTicket }
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

  Future<int> fetchMyCredit() async {
    final response = await _client.dio.get('/users/me/credit');
    return response.data['credit'] as int;
  }

  /// GET /users/me/summary -> { user, credit, tickets }
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
      credit: (data['credit'] as num?)?.toInt() ?? 0,
      tickets: tickets,
    );
  }

  Future<void> buyCredit(int coins) async {
    await _client.dio.post('/users/me/credit/increase', data: {'amount': coins});
  }

  /// ?곸젏: 肄붿씤?쇰줈 ?곗폆 援щℓ. 1肄붿씤=1?대엺沅? 5肄붿씤=1?깅줉沅?
  Future<void> purchaseTicket(String product, {int quantity = 1}) async {
    await _client.dio.post('/users/me/credit/increase', data: {'product': product, 'quantity': quantity});
  }
}

