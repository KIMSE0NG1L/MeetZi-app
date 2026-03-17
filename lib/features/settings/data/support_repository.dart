import 'package:dio/dio.dart';
import 'package:nearo_app/shared/api/api_client.dart';

class SupportRepository {
  SupportRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// 문의 전송. 답변은 앱 내 문의함에서 확인.
  Future<void> sendInquiry({
    required String category,
    required String message,
  }) async {
    await _client.dio.post(
      '/support/inquiry',
      data: {'category': category, 'message': message},
    );
  }

  /// 내 문의 목록 (로그인 시 앱 내 문의함용)
  /// 
  /// 예외:
  /// - [DioException]: 네트워크 오류 또는 서버 에러
  Future<List<Map<String, dynamic>>> getMyInquiries() async {
    final res = await _client.dio.get<List>('/support/inquiries');
    final list = res.data;
    if (list == null) return [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
