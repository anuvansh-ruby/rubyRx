// Base API Response Model
class ApiResponse<T> {
  final String status;
  final String? message;
  final T? data;
  final String? error;

  ApiResponse({required this.status, this.message, this.data, this.error});

  bool get isSuccess => status.toUpperCase() == 'SUCCESS';
  bool get isFailure => !isSuccess;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? fromJsonT,
  ) {
    return ApiResponse<T>(
      status: json['status'] ?? 'FAILURE',
      message: json['message'],
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'] as Map<String, dynamic>)
          : json['data'],
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'status': status, 'message': message, 'data': data, 'error': error};
  }
}
