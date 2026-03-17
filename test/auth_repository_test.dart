import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';
import 'package:nearo_app/shared/api/api_client.dart';
import 'package:nearo_app/shared/utils/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:dio/dio.dart';

// Mock classes
class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

class MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  late AuthRepository authRepository;
  late MockApiClient mockApiClient;
  late MockDio mockDio;
  late MockTokenStorage mockTokenStorage;

  setUp(() {
    mockApiClient = MockApiClient();
    mockDio = MockDio();
    mockTokenStorage = MockTokenStorage();
    authRepository = AuthRepository(
      client: mockApiClient,
      tokenStorage: mockTokenStorage,
    );

    when(() => mockApiClient.dio).thenReturn(mockDio);
  });

  group('AuthRepository', () {
    group('getProfile', () {
      test('should return profile data when API call succeeds', () async {
        // Arrange
        final mockResponse = Response(
          data: {
            'user': {'id': '1', 'nickname': 'testuser'},
            'message': '프로필 조회 완료!'
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/users/me'),
        );

        when(() => mockDio.get('/users/me')).thenAnswer(
          (_) async => mockResponse,
        );

        // Act
        final result = await authRepository.getProfile();

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['user']['nickname'], 'testuser');
        verify(() => mockDio.get('/users/me')).called(1);
      });

      test('should throw exception when API call fails', () async {
        // Arrange
        when(() => mockDio.get('/users/me')).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/users/me'),
            response: Response(
              statusCode: 401,
              requestOptions: RequestOptions(path: '/users/me'),
            ),
          ),
        );

        // Act & Assert
        expect(() => authRepository.getProfile(forceRefresh: true), throwsA(isA<DioException>()));
        verify(() => mockDio.get('/users/me')).called(1);
      });
    });

    group('saveTokens', () {
      test('should save tokens using TokenStorage', () async {
        // Arrange
        const accessToken = 'access123';
        const refreshToken = 'refresh456';

        when(() => mockTokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        )).thenAnswer((_) async => null);

        // Act
        await authRepository.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );

        // Assert
        verify(() => mockTokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        )).called(1);
      });
    });
  });
}