import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nearo_app/shared/api/api_client.dart';
import 'package:nearo_app/shared/api/endpoints.dart';

class PhotoRepository {
  final ApiClient _client;

  PhotoRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<dynamic>> getMyPhotos() async {
    final response = await _client.dio.get(ApiEndpoints.photos);
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> uploadPhoto({required String storageKey}) async {
    final response = await _client.dio.post(
      ApiEndpoints.photosUpload,
      data: {'storageKey': storageKey},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getUploadUrl() async {
    final response = await _client.dio.get('${ApiEndpoints.photos}/upload-url');
    return response.data as Map<String, dynamic>;
  }

  Future<void> uploadToStorage({
    required String signedUrl,
    required List<int> fileBytes,
    required String contentType,
    void Function(int count, int total)? onProgress,
  }) async {
    // DIO나 HTTP를 이용해 Signed URL로 바로 바이너리 데이터를 PUT 전송
    await Dio().put(
      signedUrl,
      data: Stream.fromIterable([fileBytes]),
      options: Options(
        headers: {
          'Content-Type': contentType,
          'Content-Length': fileBytes.length.toString(),
        },
      ),
      onSendProgress: onProgress,
    );
  }

  Future<Map<String, dynamic>> uploadPhotoFile({
    required List<int> compressedBytes,
    void Function(int count, int total)? onProgress,
  }) async {
    // 1. 서버에 Signed URL 요청
    final uploadInfo = await getUploadUrl();
    final signedUrl = uploadInfo['signedUrl'] as String;
    final storageKey = uploadInfo['storageKey'] as String;

    // 2. 받은 URL을 통해 스토리지로 직접 업로드 (압축된 이미지)
    await uploadToStorage(
      signedUrl: signedUrl,
      fileBytes: compressedBytes,
      contentType: 'image/jpeg',
      onProgress: onProgress,
    );

    // 3. 업로드 완료를 서버 DB에 기록
    final response = await _client.dio.post(
      ApiEndpoints.photosUpload,
      data: {'storageKey': storageKey},
    );
    
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deletePhoto({required String photoId}) async {
    final response = await _client.dio.delete(ApiEndpoints.photoById(photoId));
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateVisibility({
    required String photoId,
    required String visibility,
  }) async {
    final response = await _client.dio.patch(
      ApiEndpoints.photoVisibility(photoId),
      data: {'visibility': visibility},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> setPrimary({required String photoId}) async {
    final response = await _client.dio.patch(
      ApiEndpoints.photoPrimary(photoId),
    );
    return response.data as Map<String, dynamic>;
  }
}
