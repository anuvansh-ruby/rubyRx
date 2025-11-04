import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:ruby_rx_flutter/data/services/hive_storage_service.dart';
import '../config/app_config.dart';

/// Common API client for consistent JWT token handling and error management
class ApiClient extends GetxService {
  static String get baseUrl => AppConfig.baseUrl;

  final http.Client _httpClient = http.Client();

  @override
  void onClose() {
    _httpClient.close();
    super.onClose();
  }

  /// Get authentication token from secure storage
  Future<String?> _getAuthToken() async {
    try {
      final token = await HiveStorageService.getAuthToken();
      if (token == null) {
        print('⚠️ No auth token found in storage');
      } else {
        print('🔑 Auth token retrieved successfully');
      }
      return token;
    } catch (e) {
      print('❌ Error getting auth token: $e');
      return null;
    }
  }

  /// Get standard headers with JWT authentication
  Future<Map<String, String>> _getHeaders({
    Map<String, String>? additionalHeaders,
  }) async {
    final token = await _getAuthToken();

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = token;
    }

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// Get headers without authentication (for endpoints that don't require auth)
  Future<Map<String, String>> _getHeadersWithoutAuth({
    Map<String, String>? additionalHeaders,
  }) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// Get headers for multipart/form-data requests
  Future<Map<String, String>> _getMultipartHeaders({
    Map<String, String>? additionalHeaders,
  }) async {
    final token = await _getAuthToken();

    final headers = <String, String>{'Accept': 'application/json'};

    if (token != null) {
      headers['Authorization'] = token;
    }

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// Handle common HTTP responses and errors
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    print('📥 Response status: ${response.statusCode}');
    print('📥 Response body: ${response.body}');

    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonResponse = jsonDecode(response.body);

        // Handle both formats: {"success": true} and {"status": "Success"}
        final isSuccess =
            jsonResponse['success'] == true ||
            jsonResponse['status'] == 'Success' ||
            jsonResponse['status'] == 'success';

        if (isSuccess) {
          final data = jsonResponse['data'];
          return ApiResponse<T>(
            success: true,
            data: data != null ? fromJson(data) : null,
            message: jsonResponse['message'] ?? 'Success',
          );
        } else {
          return ApiResponse<T>(
            success: false,
            data: null,
            message: jsonResponse['message'] ?? 'Operation failed',
          );
        }
      } else {
        return _handleHttpError<T>(response);
      }
    } on FormatException catch (e) {
      print('❌ JSON parsing error: $e');
      return ApiResponse<T>(
        success: false,
        data: null,
        message: 'Server response format error. Please try again.',
        error: 'FormatException: $e',
      );
    } catch (e) {
      print('❌ Response handling error: $e');
      return ApiResponse<T>(
        success: false,
        data: null,
        message: 'Unexpected error occurred. Please try again.',
        error: 'Exception: $e',
      );
    }
  }

  /// Handle HTTP error responses
  ApiResponse<T> _handleHttpError<T>(http.Response response) {
    String errorMessage;

    switch (response.statusCode) {
      case 400:
        errorMessage = 'Invalid request. Please check your inputs.';
        break;
      case 401:
        errorMessage = 'Authentication expired. Please login again.';
        _handleAuthenticationError();
        break;
      case 403:
        errorMessage = 'Access denied. You do not have permission.';
        break;
      case 404:
        errorMessage = 'Resource not found. Please contact support.';
        break;
      case 422:
        errorMessage = 'Validation failed. Please check your data.';
        break;
      case 429:
        errorMessage = 'Too many requests. Please try again later.';
        break;
      case 500:
        errorMessage = 'Server error. Please try again later.';
        break;
      case 502:
        errorMessage = 'Service unavailable. Please try again later.';
        break;
      case 503:
        errorMessage = 'Service temporarily unavailable.';
        break;
      default:
        errorMessage =
            'Network error (${response.statusCode}). Please try again.';
    }

    // Try to extract detailed error from response body
    try {
      final errorResponse = jsonDecode(response.body);
      if (errorResponse['message'] != null) {
        errorMessage = errorResponse['message'];
      } else if (errorResponse['error'] != null) {
        errorMessage = errorResponse['error'];
      }
    } catch (e) {
      // Use default error message if JSON parsing fails
    }

    return ApiResponse<T>(
      success: false,
      data: null,
      message: errorMessage,
      error: 'HTTP ${response.statusCode}: ${response.body}',
    );
  }

  /// Handle authentication errors by clearing tokens and redirecting to login
  void _handleAuthenticationError() {
    HiveStorageService.clearAuthToken();
    HiveStorageService.setLoginStatus(false);

    // Navigate to login page if using GetX routing
    if (Get.currentRoute != '/login') {
      Get.offAllNamed('/login');
    }
  }

  /// Make GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, String>? queryParams,
    Map<String, String>? additionalHeaders,
  }) async {
    try {
      print('📤 GET request to: $endpoint');

      final token = await _getAuthToken();
      if (token == null) {
        print('⚠️ No auth token available for GET request');
        return ApiResponse<T>(
          success: false,
          data: null,
          message: 'Authentication required. Please login again.',
          error: 'No auth token',
        );
      }

      final headers = await _getHeaders(additionalHeaders: additionalHeaders);

      Uri url = Uri.parse('$baseUrl/$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        url = url.replace(queryParameters: queryParams);
      }

      print('🔗 URL: $url');
      print('📋 Headers: $headers');

      final response = await _httpClient
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      return _handleResponse<T>(response, fromJson);
    } on TimeoutException {
      return ApiResponse<T>(
        success: false,
        data: null,
        message: 'Request timed out. Please check your connection.',
        error: 'TimeoutException',
      );
    } on SocketException {
      return ApiResponse<T>(
        success: false,
        data: null,
        message: 'Network error. Please check your internet connection.',
        error: 'SocketException',
      );
    } catch (e) {
      print('❌ GET request error: $e');
      return ApiResponse<T>(
        success: false,
        data: null,
        message: 'Request failed. Please try again.',
        error: 'Exception: $e',
      );
    }
  }

  /// Make POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson, {
    dynamic body,
    Map<String, String>? additionalHeaders,
    bool requireAuth = true, // Allow disabling auth for specific endpoints
  }) async {
    try {
      print('📤 POST request to: $endpoint');

      final token = await _getAuthToken();

      // Check if auth is required and token is missing
      if (requireAuth && token == null) {
        print('⚠️ No auth token available for POST request');
        return ApiResponse<T>(
          success: false,
          data: null,
          message: 'Authentication required. Please login again.',
          error: 'No auth token',
        );
      }

      // Get headers with optional auth
      final headers = requireAuth
          ? await _getHeaders(additionalHeaders: additionalHeaders)
          : await _getHeadersWithoutAuth(additionalHeaders: additionalHeaders);

      final url = Uri.parse('$baseUrl/$endpoint');

      print('🔗 URL: $url');
      print('📋 Headers: $headers');
      print('📋 Body: ${jsonEncode(body)}');

      final response = await _httpClient
          .post(url, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));

      return _handleResponse<T>(response, fromJson);
    } on TimeoutException {
      return ApiResponse<T>(
        success: false,
        data: null,
        message: 'Request timed out. Please check your connection.',
        error: 'TimeoutException',
      );
    } on SocketException {
      return ApiResponse<T>(
        success: false,
        data: null,
        message: 'Network error. Please check your internet connection.',
        error: 'SocketException',
      );
    } catch (e) {
      print('❌ POST request error: $e');
      return ApiResponse<T>(
        success: false,
        data: null,
        message: 'Request failed. Please try again.',
        error: 'Exception: $e',
      );
    }
  }

  /// Make PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson, {
    dynamic body,
    Map<String, String>? additionalHeaders,
  }) async {
    try {
      print('📤 PUT request to: $endpoint');

      final token = await _getAuthToken();
      if (token == null) {
        print('⚠️ No auth token available for PUT request');
        return ApiResponse<T>(
          success: false,
          data: null,
          message: 'Authentication required. Please login again.',
          error: 'No auth token',
        );
      }

      final headers = await _getHeaders(additionalHeaders: additionalHeaders);
      final url = Uri.parse('$baseUrl/$endpoint');

      final response = await _httpClient
          .put(url, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));

      return _handleResponse<T>(response, fromJson);
    } on TimeoutException {
      return ApiResponse<T>(
        success: false,
        data: null,
        message: 'Request timed out. Please check your connection.',
        error: 'TimeoutException',
      );
    } on SocketException {
      return ApiResponse<T>(
        success: false,
        data: null,
        message: 'Network error. Please check your internet connection.',
        error: 'SocketException',
      );
    } catch (e) {
      print('❌ PUT request error: $e');
      return ApiResponse<T>(
        success: false,
        data: null,
        message: 'Request failed. Please try again.',
        error: 'Exception: $e',
      );
    }
  }

  /// Make DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, String>? additionalHeaders,
  }) async {
    try {
      print('📤 DELETE request to: $endpoint');

      final token = await _getAuthToken();
      if (token == null) {
        print('⚠️ No auth token available for DELETE request');
        return ApiResponse<T>(
          success: false,
          data: null,
          message: 'Authentication required. Please login again.',
          error: 'No auth token',
        );
      }

      final headers = await _getHeaders(additionalHeaders: additionalHeaders);
      final url = Uri.parse('$baseUrl/$endpoint');

      final response = await _httpClient
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      return _handleResponse<T>(response, fromJson);
    } on TimeoutException {
      return ApiResponse<T>(
        success: false,
        data: null,
        message: 'Request timed out. Please check your connection.',
        error: 'TimeoutException',
      );
    } on SocketException {
      return ApiResponse<T>(
        success: false,
        data: null,
        message: 'Network error. Please check your internet connection.',
        error: 'SocketException',
      );
    } catch (e) {
      print('❌ DELETE request error: $e');
      return ApiResponse<T>(
        success: false,
        data: null,
        message: 'Request failed. Please try again.',
        error: 'Exception: $e',
      );
    }
  }

  /// Make multipart request (for file uploads)
  Future<ApiResponse<T>> multipart<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, String>? fields,
    Map<String, String>? files,
    Map<String, String>? additionalHeaders,
  }) async {
    try {
      print('📤 MULTIPART request to: $endpoint');

      final token = await _getAuthToken();
      if (token == null) {
        print('⚠️ No auth token available for MULTIPART request');
        return ApiResponse<T>(
          success: false,
          data: null,
          message: 'Authentication required. Please login again.',
          error: 'No auth token',
        );
      }

      final headers = await _getMultipartHeaders(
        additionalHeaders: additionalHeaders,
      );
      final url = Uri.parse('$baseUrl/$endpoint');

      final request = http.MultipartRequest('POST', url);
      request.headers.addAll(headers);

      // Add text fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      // Add files
      if (files != null) {
        for (final entry in files.entries) {
          request.files.add(
            await http.MultipartFile.fromPath(entry.key, entry.value),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse<T>(response, fromJson);
    } on TimeoutException {
      return ApiResponse<T>(
        success: false,
        data: null,
        message: 'Request timed out. Please check your connection.',
        error: 'TimeoutException',
      );
    } on SocketException {
      return ApiResponse<T>(
        success: false,
        data: null,
        message: 'Network error. Please check your internet connection.',
        error: 'SocketException',
      );
    } catch (e) {
      print('❌ MULTIPART request error: $e');
      return ApiResponse<T>(
        success: false,
        data: null,
        message: 'Request failed. Please try again.',
        error: 'Exception: $e',
      );
    }
  }

  /// Test API connection
  Future<bool> testConnection() async {
    try {
      final url = Uri.parse('$baseUrl/health');
      final response = await _httpClient
          .get(url)
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Connection test failed: $e');
      return false;
    }
  }
}

/// Common API response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String message;
  final String? error;

  ApiResponse({
    required this.success,
    required this.data,
    required this.message,
    this.error,
  });

  factory ApiResponse.success(T data, String message) {
    return ApiResponse<T>(success: true, data: data, message: message);
  }

  factory ApiResponse.failure(String message, [String? error]) {
    return ApiResponse<T>(
      success: false,
      data: null,
      message: message,
      error: error,
    );
  }

  @override
  String toString() {
    return 'ApiResponse{success: $success, data: $data, message: $message, error: $error}';
  }
}
