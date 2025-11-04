import 'package:dio/dio.dart';

// Error Response Model
class ApiError implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final Map<String, dynamic>? details;
  final String? endpoint;

  ApiError({
    required this.message,
    this.statusCode,
    this.code,
    this.details,
    this.endpoint,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      message: json['message'] ?? 'Unknown error occurred',
      statusCode: json['statusCode'],
      code: json['code'],
      details: json['details'],
      endpoint: json['endpoint'],
    );
  }

  factory ApiError.fromDioError(dynamic error) {
    String message = 'Unknown error occurred';
    int? statusCode;
    String? code;
    Map<String, dynamic>? details;
    String? endpoint = error.requestOptions?.path;

    if (error.response != null) {
      statusCode = error.response.statusCode;
      final responseData = error.response.data;

      if (responseData is Map<String, dynamic>) {
        message =
            responseData['message'] ?? _getDefaultErrorMessage(statusCode);
        code = responseData['code'];
        details = responseData;
      } else {
        message = _getDefaultErrorMessage(statusCode);
      }
    } else {
      // Network or other errors
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          message =
              'Connection timeout. Please check your internet connection.';
          code = 'CONNECTION_TIMEOUT';
          break;
        case DioExceptionType.receiveTimeout:
          message = 'Request timeout. Please try again.';
          code = 'RECEIVE_TIMEOUT';
          break;
        case DioExceptionType.sendTimeout:
          message = 'Send timeout. Please try again.';
          code = 'SEND_TIMEOUT';
          break;
        case DioExceptionType.connectionError:
          message = 'Network error. Please check your internet connection.';
          code = 'CONNECTION_ERROR';
          break;
        case DioExceptionType.badCertificate:
          message = 'Security certificate error.';
          code = 'BAD_CERTIFICATE';
          break;
        case DioExceptionType.cancel:
          message = 'Request was cancelled.';
          code = 'REQUEST_CANCELLED';
          break;
        default:
          message = error.message ?? 'Network error occurred';
          code = 'NETWORK_ERROR';
      }
    }

    return ApiError(
      message: message,
      statusCode: statusCode,
      code: code,
      details: details,
      endpoint: endpoint,
    );
  }

  static String _getDefaultErrorMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return 'Unauthorized. Please login again.';
      case 403:
        return 'Forbidden. You don\'t have permission to access this resource.';
      case 404:
        return 'Resource not found.';
      case 408:
        return 'Request timeout. Please try again.';
      case 409:
        return 'Conflict. The request conflicts with current state.';
      case 422:
        return 'Validation error. Please check your input.';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
        return 'Internal server error. Please try again later.';
      case 502:
        return 'Bad gateway. Please try again later.';
      case 503:
        return 'Service unavailable. Please try again later.';
      case 504:
        return 'Gateway timeout. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'statusCode': statusCode,
      'code': code,
      'details': details,
      'endpoint': endpoint,
    };
  }

  @override
  String toString() {
    return 'ApiError(message: $message, statusCode: $statusCode, code: $code, endpoint: $endpoint)';
  }

  // Helper methods for specific error types
  bool get isNetworkError => [
    'CONNECTION_TIMEOUT',
    'RECEIVE_TIMEOUT',
    'SEND_TIMEOUT',
    'CONNECTION_ERROR',
    'NETWORK_ERROR',
  ].contains(code);

  bool get isServerError => statusCode != null && statusCode! >= 500;

  bool get isClientError =>
      statusCode != null && statusCode! >= 400 && statusCode! < 500;

  bool get isUnauthorized => statusCode == 401;

  bool get isForbidden => statusCode == 403;

  bool get isNotFound => statusCode == 404;

  bool get isValidationError => statusCode == 422;

  bool get isRateLimited => statusCode == 429;
}
