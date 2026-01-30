import 'package:nearo_app/shared/api/api_client.dart';
import 'package:nearo_app/shared/api/endpoints.dart';

class SubscriptionRepository {
  final ApiClient _client;

  SubscriptionRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<Map<String, dynamic>> getSubscription() async {
    final response = await _client.dio.get(ApiEndpoints.subscription);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> cancelSubscription() async {
    final response = await _client.dio.post(ApiEndpoints.subscriptionCancel);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> pauseSubscription() async {
    final response = await _client.dio.patch(ApiEndpoints.subscriptionPause);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> resumeSubscription() async {
    final response = await _client.dio.patch(ApiEndpoints.subscriptionResume);
    return response.data as Map<String, dynamic>;
  }

  Future<bool> isSubscriptionActive() async {
    final response = await _client.dio.get(ApiEndpoints.subscriptionIsActive);
    final data = response.data as Map<String, dynamic>;
    return data['isActive'] == true;
  }
}
