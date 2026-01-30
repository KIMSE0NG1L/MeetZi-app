class ApiResponse<T> {
  final T data;
  final String? message;

  ApiResponse({required this.data, this.message});

  factory ApiResponse.fromJson(
      Map<String, dynamic> json, T Function(Object?) map) {
    return ApiResponse(
      data: map(json['data']),
      message: json['message'] as String?,
    );
  }
}
