import 'dart:async';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'api_client.dart';
import '../models/api_response.dart';
import '../../utils/platform_file_helper.dart';

class PrescriptionApiService {
  final Dio _dio = ApiClient.instance.dio;

  // Enhanced error message based on status code
  static String getDetailedErrorMessage(DioException e) {
    switch (e.response?.statusCode) {
      case 400:
        return 'Invalid request. Please check your image and try again.';
      case 401:
        return 'Authentication failed. Please log in again.';
      case 403:
        return 'You do not have permission to upload prescriptions.';
      case 404:
        return 'Upload service not found. Please contact support.';
      case 413:
        return 'File size too large. Please compress your image and try again.';
      case 415:
        return 'Unsupported file format. Please use JPG, PNG, or similar image formats.';
      case 422:
        return 'Invalid file data. Please select a different image.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      case 500:
        return 'Server error. Please try again later or contact support.';
      case 502:
        return 'Service temporarily unavailable. Please try again in a few minutes.';
      case 503:
        return 'Service maintenance in progress. Please try again later.';
      case 504:
        return 'Request timeout. Please check your internet connection and try again.';
      default:
        if (e.type == DioExceptionType.connectionTimeout) {
          return 'Connection timeout. Please check your internet connection.';
        } else if (e.type == DioExceptionType.sendTimeout) {
          return 'Upload timeout. Please try with a smaller image or better connection.';
        } else if (e.type == DioExceptionType.receiveTimeout) {
          return 'Response timeout. The server took too long to respond.';
        } else if (e.type == DioExceptionType.connectionError) {
          return 'Connection error. Please check your internet connection.';
        } else if (e.type == DioExceptionType.cancel) {
          return 'Upload was cancelled.';
        }
        return e.message ?? 'Network error occurred. Please try again.';
    }
  }

  // Upload prescription image for processing (now uses XFile for cross-platform compatibility)
  Future<ApiResponse<Map<String, dynamic>>> uploadPrescriptionImage(
    XFile imageFile, {
    String? additionalNotes,
    int? patientId,
  }) async {
    try {
      print('🚀 Starting cross-platform prescription upload...');
      print('📱 Platform: ${PlatformFileHelper.isWeb ? 'Web' : 'Mobile'}');
      print('📄 File info - Path: ${imageFile.path}');
      print('📄 File info - Name: ${imageFile.name}');
      print('📄 File info - MimeType: ${imageFile.mimeType}');

      // Cross-platform file validation using our utility
      final validationError = await PlatformFileHelper.validateImageFile(
        imageFile,
      );
      if (validationError != null) {
        print('❌ File validation failed: $validationError');
        return ApiResponse<Map<String, dynamic>>(
          status: 'FAILURE',
          message: validationError,
          error: 'FILE_VALIDATION_ERROR',
        );
      }

      print('✅ File validation passed');

      // Create multipart file using cross-platform helper
      MultipartFile? multipartFile;
      try {
        multipartFile = await PlatformFileHelper.createMultipartFile(imageFile);
        print('✅ MultipartFile created successfully');
      } catch (e) {
        final errorMessage = PlatformFileHelper.getPlatformSpecificErrorMessage(
          'file reading',
          e,
        );
        print('❌ Failed to create multipart file: $errorMessage');
        return ApiResponse<Map<String, dynamic>>(
          status: 'FAILURE',
          message: errorMessage,
          error: 'FILE_READ_ERROR',
        );
      }

      // Get safe filename
      final fileName = PlatformFileHelper.getSafeFileName(imageFile);
      print('📎 Using filename: $fileName');

      final formData = FormData.fromMap({
        'prescription_image': multipartFile,
        if (additionalNotes != null && additionalNotes.trim().isNotEmpty)
          'notes': additionalNotes.trim(),
        if (patientId != null && patientId > 0) 'patient_id': patientId,
        'upload_type': 'camera_scan',
        'timestamp': DateTime.now().toIso8601String(),
      });

      print('📤 Uploading prescription image...');

      // Configure request options with timeouts
      final options = Options(
        headers: {'Content-Type': 'multipart/form-data'},
        sendTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 2),
      );

      final response = await _dio.post(
        '/v1/prescription/upload',
        data: formData,
        options: options,
      );

      print('📥 Upload response received');

      // Validate response structure
      if (response.data == null) {
        print('❌ Invalid response structure');
        return ApiResponse<Map<String, dynamic>>(
          status: 'FAILURE',
          message: 'Invalid response from server. Please try again.',
          error: 'INVALID_RESPONSE',
        );
      }

      print('✅ Upload successful');
      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json,
      );
    } on DioException catch (e) {
      final errorMessage = getDetailedErrorMessage(e);
      print('❌ Dio exception: $errorMessage');
      return ApiResponse<Map<String, dynamic>>(
        status: 'FAILURE',
        message: errorMessage,
        error: 'HTTP ${e.response?.statusCode ?? 'Unknown'}',
      );
    } on TimeoutException {
      final errorMessage =
          'Upload timeout. Please try with a smaller image or check your internet connection.';
      print('❌ Timeout exception: $errorMessage');
      return ApiResponse<Map<String, dynamic>>(
        status: 'FAILURE',
        message: errorMessage,
        error: 'TIMEOUT_ERROR',
      );
    } catch (e) {
      final errorMessage = PlatformFileHelper.getPlatformSpecificErrorMessage(
        'prescription upload',
        e,
      );
      print('❌ Unexpected exception: $errorMessage');
      return ApiResponse<Map<String, dynamic>>(
        status: 'FAILURE',
        message: errorMessage,
        error: 'UNEXPECTED_ERROR',
      );
    }
  }
}
