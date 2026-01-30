import 'package:nearo_app/shared/api/api_client.dart';
import 'package:nearo_app/shared/api/endpoints.dart';

class EnvironmentRepository {
  final ApiClient _client;

  EnvironmentRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<Map<String, dynamic>> requestEmailVerification({
    required String environmentId,
    required String email,
  }) async {
    final response = await _client.dio.post(
      ApiEndpoints.emailVerificationRequest(environmentId),
      data: {'email': email},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> confirmEmailVerification({
    required String environmentId,
    required String code,
  }) async {
    final response = await _client.dio.post(
      ApiEndpoints.emailVerificationConfirm(environmentId),
      data: {'code': code},
    );
    return response.data as Map<String, dynamic>;
  }
}
