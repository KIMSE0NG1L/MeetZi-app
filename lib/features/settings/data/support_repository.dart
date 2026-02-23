import 'package:dio/dio.dart';
import 'package:nearo_app/shared/api/api_client.dart';

class SupportRepository {
  SupportRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// 문의 전송. 입력한 이메일 주소로 답변 메일 발송.
  Future<void> sendInquiry({
    required String email,
    required String category,
    required String message,
  }) async {
    await _client.dio.post(
      '/support/inquiry',
      data: {'email': email, 'category': category, 'message': message},
    );
  }

  /// 내 문의 목록 (로그인 시 앱 내 문의함용)
  Future<List<Map<String, dynamic>>> getMyInquiries() async {
    try {
      final res = await _client.dio.get<List>('/support/inquiries');
      final list = res.data;
      if (list == null) return [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }
}
