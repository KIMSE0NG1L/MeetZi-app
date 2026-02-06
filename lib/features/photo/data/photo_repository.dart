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

  Future<Map<String, dynamic>> uploadPhotoFile({required XFile file}) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.name,
      ),
    });
    final response = await _client.dio.post(
      ApiEndpoints.photosUpload,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
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
