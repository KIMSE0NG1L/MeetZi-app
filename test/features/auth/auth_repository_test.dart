// ignore_for_file: avoid_classes_with_only_static_members, prefer_const_constructors

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nearo_app/features/auth/data/auth_repository.dart';
import 'package:nearo_app/shared/api/api_client.dart';
import 'package:nearo_app/shared/utils/token_storage.dart';

// Mock classes using mocktail
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

    // Stub the dio getter on ApiClient to return our mock Dio instance
    when(() => mockApiClient.dio).thenReturn(mockDio);

    // Instantiate AuthRepository with mock dependencies
    authRepository = AuthRepository(
      client: mockApiClient,
      tokenStorage: mockTokenStorage,
    );
  });

  group('AuthRepository Unit Tests', () {
    final tProfileData = {'id': '1', 'name': 'Test User', 'email': 'test@test.com'};
    final tSuccessResponse = Response(
      data: tProfileData,
      statusCode: 200,
      requestOptions: RequestOptions(path: '/users/me'),
    );

    test('getProfile should return user profile on successful API call', () async {
      // Arrange
      // Stub the GET request to return a successful response
      when(() => mockDio.get(any())).thenAnswer((_) async => tSuccessResponse);

      // Act
      final result = await authRepository.getProfile();

      // Assert
      // Verify that the get method was called on the mock Dio instance with the correct path
      verify(() => mockDio.get('/users/me')).called(1);
      // Verify that the result matches the data from the response
      expect(result, tProfileData);
    });

    test('getProfile should use cache on subsequent calls within TTL', () async {
      // Arrange: First call to populate cache
      when(() => mockDio.get(any())).thenAnswer((_) async => tSuccessResponse);

      // Act: First call
      await authRepository.getProfile();

      // Assert: Verify first call
      verify(() => mockDio.get('/users/me')).called(1);

      // Act: Second call
      final result = await authRepository.getProfile();

      // Assert: Verify that dio.get was NOT called again and result is from cache
      verifyNever(() => mockDio.get('/users/me'));
      expect(result, tProfileData);
    });

    test('getProfile should throw an exception when API call fails', () async {
      // Arrange
      // Stub the GET request to throw an exception
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/users/me'),
        error: 'Something went wrong',
      );
      when(() => mockDio.get(any())).thenThrow(dioException);

      // Act & Assert
      // Expect the repository method to re-throw the exception
      expect(() => authRepository.getProfile(), throwsA(isA<DioException>()));
      verify(() => mockDio.get('/users/me')).called(1);
    });

    test('logout should clear tokens and invalidate cache', () async {
      // Arrange
      // Stub the clear method on token storage
      when(() => mockTokenStorage.clear()).thenAnswer((_) async {});
      // Pre-populate cache to verify invalidation
      when(() => mockDio.get(any())).thenAnswer((_) async => tSuccessResponse);
      await authRepository.getProfile();


      // Act
      await authRepository.logout();

      // Assert
      verify(() => mockTokenStorage.clear()).called(1);

      // Verify cache is invalidated by calling getProfile again and expecting a network call
      await authRepository.getProfile();
      verify(() => mockDio.get('/users/me')).called(1); // called once now, total of two
    });
  });
}
