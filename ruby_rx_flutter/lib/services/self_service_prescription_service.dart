import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/self_service_prescription_models.dart';

/// Self-Service Prescription Service
/// Handles API calls for the new self-service prescription flow
/// where logged-in users create prescriptions for themselves
class SelfServicePrescriptionService {
  final Dio _dio;
  final String _baseUrl;

  SelfServicePrescriptionService({Dio? dio, String? baseUrl})
    : _dio = dio ?? Dio(),
      _baseUrl = baseUrl ?? 'http://localhost:3000/api';

  /// Create a self-service prescription
  /// POST /api/prescriptions/self-service
  Future<SelfServicePrescriptionResponse> createSelfServicePrescription(
    CreateSelfServicePrescriptionRequest request,
  ) async {
    try {
      print('🏥 Creating self-service prescription...');
      print('Request data: ${jsonEncode(request.toJson())}');

      final response = await _dio.post(
        '$_baseUrl/prescriptions/self-service',
        data: request.toJson(),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      print('✅ Self-service prescription created successfully');
      print('Response: ${response.data}');

      return SelfServicePrescriptionResponse.fromJson(response.data);
    } on DioException catch (e) {
      print('❌ Dio error creating self-service prescription: ${e.message}');
      print('Response data: ${e.response?.data}');

      if (e.response?.data != null) {
        try {
          return SelfServicePrescriptionResponse.fromJson(e.response!.data);
        } catch (parseError) {
          print('❌ Error parsing error response: $parseError');
        }
      }

      return SelfServicePrescriptionResponse(
        success: false,
        message: e.message ?? 'Network error occurred',
        error: e.response?.data?['error'] ?? e.message,
      );
    } catch (e) {
      print('❌ Unexpected error creating self-service prescription: $e');
      return SelfServicePrescriptionResponse(
        success: false,
        message: 'An unexpected error occurred',
        error: e.toString(),
      );
    }
  }

  /// Get enhanced prescription details by ID
  /// GET /api/prescriptions/:id/enhanced
  Future<ApiResponse<EnhancedPrescriptionDetails>> getEnhancedPrescription(
    int prescriptionId,
  ) async {
    try {
      print(
        '🔍 Fetching enhanced prescription details for ID: $prescriptionId',
      );

      final response = await _dio.get(
        '$_baseUrl/prescriptions/$prescriptionId/enhanced',
      );

      print('✅ Enhanced prescription details fetched successfully');

      if (response.data['status'] == 'SUCCESS') {
        return ApiResponse<EnhancedPrescriptionDetails>(
          success: true,
          message: response.data['message'] ?? 'Success',
          data: EnhancedPrescriptionDetails.fromJson(response.data['data']),
        );
      } else {
        return ApiResponse<EnhancedPrescriptionDetails>(
          success: false,
          message: response.data['message'] ?? 'Failed to fetch prescription',
          error: response.data['error'],
        );
      }
    } on DioException catch (e) {
      print('❌ Dio error fetching enhanced prescription: ${e.message}');
      return ApiResponse<EnhancedPrescriptionDetails>(
        success: false,
        message: e.message ?? 'Network error occurred',
        error: e.response?.data?['error'] ?? e.message,
      );
    } catch (e) {
      print('❌ Unexpected error fetching enhanced prescription: $e');
      return ApiResponse<EnhancedPrescriptionDetails>(
        success: false,
        message: 'An unexpected error occurred',
        error: e.toString(),
      );
    }
  }

  /// Get current user's prescriptions (enhanced version)
  /// GET /api/prescriptions/my-prescriptions/enhanced
  Future<MyPrescriptionsResponse> getMyEnhancedPrescriptions({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      print(
        '🔍 Fetching my enhanced prescriptions (page: $page, limit: $limit)',
      );

      final response = await _dio.get(
        '$_baseUrl/prescriptions/my-prescriptions/enhanced',
        queryParameters: {'page': page, 'limit': limit},
      );

      print('✅ My enhanced prescriptions fetched successfully');
      print('Response: ${response.data}');

      return MyPrescriptionsResponse.fromJson(response.data);
    } on DioException catch (e) {
      print('❌ Dio error fetching my prescriptions: ${e.message}');
      print('Response data: ${e.response?.data}');

      if (e.response?.data != null) {
        try {
          return MyPrescriptionsResponse.fromJson(e.response!.data);
        } catch (parseError) {
          print('❌ Error parsing error response: $parseError');
        }
      }

      return MyPrescriptionsResponse(
        success: false,
        message: e.message ?? 'Network error occurred',
        error: e.response?.data?['error'] ?? e.message,
      );
    } catch (e) {
      print('❌ Unexpected error fetching my prescriptions: $e');
      return MyPrescriptionsResponse(
        success: false,
        message: 'An unexpected error occurred',
        error: e.toString(),
      );
    }
  }

  /// Get current user's prescription summary/statistics
  /// GET /api/prescriptions/my-summary
  Future<ApiResponse<PrescriptionSummaryStats>>
  getMyPrescriptionSummary() async {
    try {
      print('📊 Fetching my prescription summary...');

      final response = await _dio.get('$_baseUrl/prescriptions/my-summary');

      print('✅ Prescription summary fetched successfully');

      if (response.data['status'] == 'SUCCESS') {
        return ApiResponse<PrescriptionSummaryStats>(
          success: true,
          message: response.data['message'] ?? 'Success',
          data: PrescriptionSummaryStats.fromJson(response.data['data']),
        );
      } else {
        return ApiResponse<PrescriptionSummaryStats>(
          success: false,
          message: response.data['message'] ?? 'Failed to fetch summary',
          error: response.data['error'],
        );
      }
    } on DioException catch (e) {
      print('❌ Dio error fetching prescription summary: ${e.message}');
      return ApiResponse<PrescriptionSummaryStats>(
        success: false,
        message: e.message ?? 'Network error occurred',
        error: e.response?.data?['error'] ?? e.message,
      );
    } catch (e) {
      print('❌ Unexpected error fetching prescription summary: $e');
      return ApiResponse<PrescriptionSummaryStats>(
        success: false,
        message: 'An unexpected error occurred',
        error: e.toString(),
      );
    }
  }

  /// Health check for self-service prescription system
  /// GET /api/prescriptions/self-service/health
  Future<ApiResponse<Map<String, dynamic>>> healthCheck() async {
    try {
      print('🔍 Checking self-service prescription API health...');

      final response = await _dio.get(
        '$_baseUrl/prescriptions/self-service/health',
      );

      print('✅ Health check completed');

      if (response.data['status'] == 'SUCCESS') {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: response.data['message'] ?? 'Success',
          data: Map<String, dynamic>.from(response.data['data']),
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Health check failed',
          error: response.data['error'],
        );
      }
    } on DioException catch (e) {
      print('❌ Dio error in health check: ${e.message}');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: e.message ?? 'Network error occurred',
        error: e.response?.data?['error'] ?? e.message,
      );
    } catch (e) {
      print('❌ Unexpected error in health check: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'An unexpected error occurred',
        error: e.toString(),
      );
    }
  }

  /// Validate prescription data before submission
  static ValidationResult validatePrescriptionRequest(
    CreateSelfServicePrescriptionRequest request,
  ) {
    List<String> errors = [];

    // Validate doctor name
    final doctorNameError =
        SelfServicePrescriptionValidation.validateDoctorName(
          request.doctorName,
        );
    if (doctorNameError != null) {
      errors.add(doctorNameError);
    }

    // Validate medicines
    final medicineErrors = SelfServicePrescriptionValidation.validateMedicines(
      request.medicines,
    );
    errors.addAll(medicineErrors);

    // Validate vitals if provided
    final bloodPressureError =
        SelfServicePrescriptionValidation.validateBloodPressure(
          request.patientBloodPressure,
        );
    if (bloodPressureError != null) {
      errors.add(bloodPressureError);
    }

    final pulseError = SelfServicePrescriptionValidation.validatePulse(
      request.patientPulse,
    );
    if (pulseError != null) {
      errors.add(pulseError);
    }

    final temperatureError =
        SelfServicePrescriptionValidation.validateTemperature(
          request.patientTemperature,
        );
    if (temperatureError != null) {
      errors.add(temperatureError);
    }

    final weightError = SelfServicePrescriptionValidation.validateWeight(
      request.patientWeight,
    );
    if (weightError != null) {
      errors.add(weightError);
    }

    final heightError = SelfServicePrescriptionValidation.validateHeight(
      request.patientHeight,
    );
    if (heightError != null) {
      errors.add(heightError);
    }

    // Validate text fields
    final diagnosisError = SelfServicePrescriptionValidation.validateTextfield(
      request.diagnosis,
      'Diagnosis',
      maxLength: 1000,
    );
    if (diagnosisError != null) {
      errors.add(diagnosisError);
    }

    final conditionsError = SelfServicePrescriptionValidation.validateTextfield(
      request.medicalConditions,
      'Medical conditions',
      maxLength: 1000,
    );
    if (conditionsError != null) {
      errors.add(conditionsError);
    }

    final notesError = SelfServicePrescriptionValidation.validateTextfield(
      request.additionalNotes,
      'Additional notes',
      maxLength: 2000,
    );
    if (notesError != null) {
      errors.add(notesError);
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }
}

/// Generic API Response wrapper
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final String? error;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });
}

/// Validation result for prescription requests
class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult({required this.isValid, required this.errors});

  String get errorMessage => errors.join('\n');
}

/// Constants for API endpoints
class ApiConstants {
  static const String baseUrl =
      'http://localhost:3000/api'; // Update with your API URL

  // Self-service prescription endpoints
  static const String createSelfServicePrescription =
      '/prescriptions/self-service';
  static const String getEnhancedPrescription = '/prescriptions/{id}/enhanced';
  static const String getMyEnhancedPrescriptions =
      '/prescriptions/my-prescriptions/enhanced';
  static const String getMyPrescriptionSummary = '/prescriptions/my-summary';
  static const String healthCheck = '/prescriptions/self-service/health';
}

/// Response status constants
class ResponseStatus {
  static const String success = 'SUCCESS';
  static const String failure = 'FAILURE';
}
