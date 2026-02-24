import 'package:dio/dio.dart';
import 'package:nearo_app/shared/api/api_client.dart';

/// 계정별 열람권/매칭권/등록권 잔량 (DB에 크레딧처럼 보관)
/// 등록권 1장 사용 → 게시판 등록 → 매칭권 1장 지급
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

class MatchingBoardRepository {
  final ApiClient _client;

  MatchingBoardRepository({ApiClient? client}) : _client = client ?? ApiClient();

  /// 게시판 프로필 목록. preferredGender: 보여줄 상대 성별 (남자 계정이면 'female', 여자 계정이면 'male')
  Future<List<Map<String, dynamic>>> fetchProfiles({String? preferredGender}) async {
    final query = <String, dynamic>{};
    if (preferredGender != null && preferredGender.isNotEmpty) {
      query['gender'] = preferredGender;
    }
    final response = await _client.dio.get('/matching-board', queryParameters: query);
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<void> registerProfile(Map<String, dynamic> profile) async {
    try {
      await _client.dio.post('/matching-board/register', data: profile);
    } on DioError catch (e) {
      final msg = e.response?.data is Map && e.response?.data['message'] != null
          ? e.response?.data['message'].toString()
          : e.message;
      throw msg ?? '등록 중 오류가 발생했습니다.';
    }
  }

  /// 가져가기 요청 전송 (상대에게 알림 감, 수락 시에만 매칭 성사 / 거절 시 매칭권 환불)
  Future<void> takeNote(String profileId) async {
    await _client.dio.post('/matching-board/take-note', data: {'profileId': profileId});
  }

  /// 내가 받은 가져가기 요청 목록 (메일함용, pending만)
  Future<List<Map<String, dynamic>>> fetchMyTakeNoteRequests() async {
    final response = await _client.dio.get('/matching-board/take-note-requests');
    final list = response.data;
    if (list is! List) return [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// 가져가기 요청 상세 조회 (요청자 프로필 포함)
  Future<Map<String, dynamic>> fetchTakeNoteRequest(String requestId) async {
    final response = await _client.dio.get('/matching-board/take-note-requests/$requestId');
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 가져가기 요청 수락 → 매칭 성사
  Future<void> acceptTakeNoteRequest(String requestId) async {
    await _client.dio.post('/matching-board/take-note-requests/$requestId/accept');
  }

  /// 가져가기 요청 거절 → 요청자 매칭권 환불
  Future<void> rejectTakeNoteRequest(String requestId) async {
    await _client.dio.post('/matching-board/take-note-requests/$requestId/reject');
  }

  /// 열람권 1장 소비 후 프로필 상세 열람 (카드 탭 시 호출)
  Future<void> consumeViewTicket(String profileId) async {
    await _client.dio.post('/matching-board/consume-view-ticket', data: {'profileId': profileId});
  }

  /// GET /users/me/tickets → { viewTicket, matchingTicket, registerTicket }
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

  Future<void> buyCredit(int coins) async {
    await _client.dio.post('/users/me/credit/increase', data: {'amount': coins});
  }

  /// 상점: 코인으로 티켓 구매. 1코인=1열람권, 5코인=1등록권
  Future<void> purchaseTicket(String product, {int quantity = 1}) async {
    await _client.dio.post('/users/me/credit/increase', data: {'product': product, 'quantity': quantity});
  }
}
