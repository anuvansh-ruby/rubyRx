import 'package:dio/dio.dart';
import 'package:ruby_rx_flutter/routes/app_routes.dart';
import '../api/api_client.dart';
import '../models/api_models.dart';

class AuthApiService {
  final Dio _dio = ApiClient.instance.dio;

  // ===== PATIENT AUTHENTICATION METHODS =====

  // Send OTP for patient login
  Future<ApiResponse<SendOtpResponse>> sendPatientLoginOtp(
    SendOtpRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/patient/send-login-otp',
        data: request.toJson(),
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => SendOtpResponse.fromJson(data),
      );
    } on DioException catch (e) {
      throw ApiError.fromDioError(e);
    } catch (e) {
      throw ApiError(message: e.toString());
    }
  }

  // Verify OTP for patient login
  Future<ApiResponse<PatientVerifyOtpResponse>> verifyPatientLoginOtp(
    VerifyOtpRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/patient/verify-login-otp',
        data: request.toJson(),
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => PatientVerifyOtpResponse.fromJson(data),
      );
    } on DioException catch (e) {
      throw ApiError.fromDioError(e);
    } catch (e) {
      throw ApiError(message: e.toString());
    }
  }

  // Resend OTP for patient login
  Future<ApiResponse<SendOtpResponse>> resendPatientLoginOtp(
    SendOtpRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/patient/resend-login-otp',
        data: request.toJson(),
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => SendOtpResponse.fromJson(data),
      );
    } on DioException catch (e) {
      throw ApiError.fromDioError(e);
    } catch (e) {
      throw ApiError(message: e.toString());
    }
  }

  // Register new patient
  Future<ApiResponse<PatientRegistrationResponse>> registerPatient(
    PatientRegistrationRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/patient/register',
        data: request.toJson(),
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => PatientRegistrationResponse.fromJson(data),
      );
    } on DioException catch (e) {
      throw ApiError.fromDioError(e);
    } catch (e) {
      throw ApiError(message: e.toString());
    }
  }

  // Setup PIN for patient
  Future<ApiResponse<SetupPinResponse>> setupPin(
    SetupPinRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/v1/patient/setup-pin',
        data: request.toJson(),
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => SetupPinResponse.fromJson(data),
      );
    } on DioException catch (e) {
      throw ApiError.fromDioError(e);
    } catch (e) {
      throw ApiError(message: e.toString());
    }
  }

  // Verify PIN for patient
  Future<ApiResponse<VerifyPinResponse>> verifyPin(
    VerifyPinRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/v1/patient/verify-pin',
        data: request.toJson(),
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => VerifyPinResponse.fromJson(data),
      );
    } on DioException catch (e) {
      throw ApiError.fromDioError(e);
    } catch (e) {
      throw ApiError(message: e.toString());
    }
  }

  // Reset PIN for patient
  Future<ApiResponse<ResetPinResponse>> resetPin(
    ResetPinRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/patient/reset-pin',
        data: request.toJson(),
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => ResetPinResponse.fromJson(data),
      );
    } on DioException catch (e) {
      throw ApiError.fromDioError(e);
    } catch (e) {
      throw ApiError(message: e.toString());
    }
  }

  // Send OTP for forgot PIN
  Future<ApiResponse<SendOtpResponse>> sendForgotPinOtp(
    SendOtpRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/patient/forgot-pin/send-otp',
        data: request.toJson(),
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => SendOtpResponse.fromJson(data),
      );
    } on DioException catch (e) {
      throw ApiError.fromDioError(e);
    } catch (e) {
      throw ApiError(message: e.toString());
    }
  }

  // Verify OTP for forgot PIN
  Future<ApiResponse<ForgotPinResponse>> verifyForgotPinOtp(
    VerifyOtpRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/patient/forgot-pin/verify-otp',
        data: request.toJson(),
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => ForgotPinResponse.fromJson(data),
      );
    } on DioException catch (e) {
      throw ApiError.fromDioError(e);
    } catch (e) {
      throw ApiError(message: e.toString());
    }
  }

  // Logout patient
  Future<ApiResponse<LogoutResponse>> logoutPatient() async {
    try {
      final response = await _dio.post('/patient/logout');

      return ApiResponse.fromJson(
        response.data,
        (data) => LogoutResponse.fromJson(data),
      );
    } on DioException catch (e) {
      throw ApiError.fromDioError(e);
    } catch (e) {
      throw ApiError(message: e.toString());
    }
  }

  // ===== NEW REGISTRATION FLOW METHODS =====

  // Register new user (full registration details)
  Future<ApiResponse<Map<String, dynamic>>> registerUser(
    Map<String, dynamic> request,
  ) async {
    try {
      final response = await _dio.post('/register-user', data: request);

      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      throw ApiError.fromDioError(e);
    } catch (e) {
      throw ApiError(message: e.toString());
    }
  }

  // Setup PIN after registration
  Future<ApiResponse<Map<String, dynamic>>> setupPinAfterRegistration(
    Map<String, dynamic> request,
  ) async {
    try {
      final response = await _dio.post(
        '/setup-pin-after-registration',
        data: request,
      );

      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      throw ApiError.fromDioError(e);
    } catch (e) {
      throw ApiError(message: e.toString());
    }
  }

  // ===== LEGACY PHONE OTP METHODS (for backwards compatibility) =====

  // Send OTP to phone number
  Future<ApiResponse<SendOtpResponse>> sendOtp(SendOtpRequest request) async {
    try {
      final response = await _dio.post(
        '/phone/send-otp',
        data: request.toJson(),
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => SendOtpResponse.fromJson(data),
      );
    } on DioException catch (e) {
      throw ApiError.fromDioError(e);
    } catch (e) {
      throw ApiError(message: e.toString());
    }
  }

  // Verify OTP and get auth token (Updated for new authentication flow)
  Future<ApiResponse<Map<String, dynamic>>> verifyPhoneOtp(
    VerifyOtpRequest request,
  ) async {
    try {
      final response = await _dio.post(
        AppRoutes.otpVerify,
        data: request.toJson(),
      );

      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      throw ApiError.fromDioError(e);
    } catch (e) {
      throw ApiError(message: e.toString());
    }
  }

  // Verify OTP and get auth token (Legacy method)
  Future<ApiResponse<VerifyOtpResponse>> verifyOtp(
    VerifyOtpRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/phone/verify-otp',
        data: request.toJson(),
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => VerifyOtpResponse.fromJson(data),
      );
    } on DioException catch (e) {
      throw ApiError.fromDioError(e);
    } catch (e) {
      throw ApiError(message: e.toString());
    }
  }

  // Resend OTP
  Future<ApiResponse<SendOtpResponse>> resendOtp(
    ResendOtpRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/phone/resend-otp',
        data: request.toJson(),
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => SendOtpResponse.fromJson(data),
      );
    } on DioException catch (e) {
      throw ApiError.fromDioError(e);
    } catch (e) {
      throw ApiError(message: e.toString());
    }
  }

  // Get user data (protected endpoint)
  Future<ApiResponse<Map<String, dynamic>>> getUserData() async {
    try {
      final response = await _dio.post('/get-user-data');

      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      throw ApiError.fromDioError(e);
    } catch (e) {
      throw ApiError(message: e.toString());
    }
  }

  // Logout (if you have a logout endpoint)
  Future<ApiResponse<Map<String, dynamic>>> logout() async {
    try {
      final response = await _dio.post('/logout');

      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      throw ApiError.fromDioError(e);
    } catch (e) {
      throw ApiError(message: e.toString());
    }
  }
}
