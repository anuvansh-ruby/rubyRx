import '../api/auth_api_service.dart';
import '../models/api_models.dart';
import '../services/hive_storage_service.dart';
import '../../models/user_model.dart';

class AuthRepository {
  final AuthApiService _authApiService = AuthApiService();

  // ===== PATIENT AUTHENTICATION METHODS =====

  // Send OTP for patient login
  Future<ApiResponse<SendOtpResponse>> sendPatientLoginOtp(
    String phoneNumber,
  ) async {
    try {
      final request = SendOtpRequest(phoneNumber: phoneNumber);
      final response = await _authApiService.sendPatientLoginOtp(request);

      if (response.isSuccess) {
        // Store phone number for later use
        await HiveStorageService.setPhoneNumber(phoneNumber);
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Verify OTP for patient login
  Future<ApiResponse<PatientVerifyOtpResponse>> verifyPatientLoginOtp(
    String phoneNumber,
    String otp,
  ) async {
    try {
      final request = VerifyOtpRequest(phoneNumber: phoneNumber, otp: otp);

      final response = await _authApiService.verifyPatientLoginOtp(request);

      if (response.isSuccess && response.data != null) {
        // Store authentication data
        await HiveStorageService.setAuthToken(response.data!.token);
        await HiveStorageService.setLoginStatus(true);
        await HiveStorageService.setPhoneNumber(phoneNumber);

        // Store patient data
        await _storePatientData(response.data!.patientInfo);
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Resend OTP for patient login
  Future<ApiResponse<SendOtpResponse>> resendPatientLoginOtp(
    String phoneNumber,
  ) async {
    try {
      final request = SendOtpRequest(phoneNumber: phoneNumber);
      return await _authApiService.resendPatientLoginOtp(request);
    } catch (e) {
      rethrow;
    }
  }

  // Register new patient
  Future<ApiResponse<PatientRegistrationResponse>> registerPatient({
    required String phoneNumber,
    required String email,
    required String firstName,
    required String lastName,
    required DateTime dateOfBirth,
    String? address,
    String? nationalIdType,
    String? nationalIdNumber,
  }) async {
    try {
      final request = PatientRegistrationRequest(
        phoneNumber: phoneNumber,
        email: email,
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth.toIso8601String(),
        address: address,
        nationalIdType: nationalIdType,
        nationalIdNumber: nationalIdNumber,
      );

      final response = await _authApiService.registerPatient(request);

      if (response.isSuccess && response.data != null) {
        // Store authentication data
        await HiveStorageService.setAuthToken(response.data!.token);
        await HiveStorageService.setLoginStatus(true);
        await HiveStorageService.setPhoneNumber(phoneNumber);

        // Store patient data
        await _storePatientData(response.data!.patient);
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Setup PIN for patient
  Future<ApiResponse<SetupPinResponse>> setupPin(String pin) async {
    try {
      final request = SetupPinRequest(pin: pin);
      final response = await _authApiService.setupPin(request);

      if (response.isSuccess) {
        // Store locally that PIN is set up
        await HiveStorageService.setPinSetupStatus(true);
        await HiveStorageService.setAppPin(pin);
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Verify PIN for patient access
  Future<ApiResponse<VerifyPinResponse>> verifyPin(
    String phoneNumber,
    String pin,
  ) async {
    try {
      final request = VerifyPinRequest(phoneNumber: phoneNumber, pin: pin);
      final response = await _authApiService.verifyPin(request);

      if (response.isSuccess && response.data != null) {
        // Store auth data and update local storage
        await HiveStorageService.setAuthToken(response.data!.token);
        await HiveStorageService.setLoginStatus(true);

        // Store patient data
        await _storePatientData(response.data!.patientInfo);
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Reset PIN for patient
  Future<ApiResponse<ResetPinResponse>> resetPin(String newPin) async {
    try {
      final request = ResetPinRequest(newPin: newPin);
      final response = await _authApiService.resetPin(request);

      if (response.isSuccess) {
        // Update local PIN storage
        await HiveStorageService.setAppPin(newPin);
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Send OTP for forgot PIN
  Future<ApiResponse<SendOtpResponse>> sendForgotPinOtp(
    String phoneNumber,
  ) async {
    try {
      final request = SendOtpRequest(phoneNumber: phoneNumber);
      return await _authApiService.sendForgotPinOtp(request);
    } catch (e) {
      rethrow;
    }
  }

  // Verify OTP for forgot PIN
  Future<ApiResponse<ForgotPinResponse>> verifyForgotPinOtp(
    String phoneNumber,
    String otp,
  ) async {
    try {
      final request = VerifyOtpRequest(phoneNumber: phoneNumber, otp: otp);

      final response = await _authApiService.verifyForgotPinOtp(request);

      if (response.isSuccess && response.data != null) {
        // Store reset token temporarily
        await HiveStorageService.setResetToken(response.data!.resetToken);
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Helper method to store patient data
  Future<void> _storePatientData(PatientInfo patient) async {
    final userModel = UserModel.fromPatientInfo(
      patient,
      token: HiveStorageService.getAuthToken(),
      hasPinSetup: HiveStorageService.getPinSetupStatus(),
    );

    await HiveStorageService.setUserData(userModel.toJson());
  }

  Future<ApiResponse<PatientVerifyOtpResponse>> verifyPhoneOtp(
    String phoneNumber,
    String otp,
  ) async {
    try {
      final request = VerifyOtpRequest(phoneNumber: phoneNumber, otp: otp);
      return await _authApiService.verifyPatientLoginOtp(request);
    } catch (e) {
      rethrow;
    }
  }

  // Send OTP to phone number (legacy)
  Future<ApiResponse<SendOtpResponse>> sendOtp(String phoneNumber) async {
    try {
      final request = SendOtpRequest(phoneNumber: phoneNumber);
      final response = await _authApiService.sendOtp(request);

      if (response.isSuccess) {
        // Store phone number for later use
        await HiveStorageService.setPhoneNumber(phoneNumber);
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Verify OTP and complete login (legacy)
  Future<ApiResponse<VerifyOtpResponse>> verifyOtp(
    String phoneNumber,
    String otp, {
    String? name,
  }) async {
    try {
      final request = VerifyOtpRequest(
        phoneNumber: phoneNumber,
        otp: otp,
        name: name,
      );

      final response = await _authApiService.verifyOtp(request);

      if (response.isSuccess && response.data != null) {
        // Store auth token and user data
        await HiveStorageService.setAuthToken(response.data!.token);
        await HiveStorageService.setLoginStatus(true);

        // Store user data
        final userData = {
          'phoneNumber': response.data!.user.phoneNumber,
          'name': response.data!.user.name,
          'verified': response.data!.user.verified,
        };
        await HiveStorageService.setUserData(userData);
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Resend OTP (legacy)
  Future<ApiResponse<SendOtpResponse>> resendOtp(String phoneNumber) async {
    try {
      final request = ResendOtpRequest(phoneNumber: phoneNumber);
      return await _authApiService.resendOtp(request);
    } catch (e) {
      rethrow;
    }
  }

  // Get user data from API (legacy)
  Future<ApiResponse<Map<String, dynamic>>> getUserData() async {
    try {
      return await _authApiService.getUserData();
    } catch (e) {
      rethrow;
    }
  }

  // ===== COMMON METHODS =====

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final token = HiveStorageService.getAuthToken();
      final loginStatus = HiveStorageService.getLoginStatus();
      return token != null && token.isNotEmpty && loginStatus;
    } catch (e) {
      return false;
    }
  }

  // Get stored user data
  Future<UserModel?> getStoredUser() async {
    try {
      final userData = HiveStorageService.getUserData();
      if (userData != null) {
        return UserModel.fromJson(userData);
      }

      // Fallback to basic data if user data not available
      final phoneNumber = HiveStorageService.getPhoneNumber();
      final token = HiveStorageService.getAuthToken();

      if (phoneNumber != null && token != null) {
        return UserModel(phone: phoneNumber, token: token, isLoggedIn: true);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      // Call logout API if available
      try {
        await _authApiService.logoutPatient();
      } catch (e) {
        // Continue with local logout even if API fails
        print('Logout API call failed: $e');
      }

      // Clear all stored data
      await HiveStorageService.clearAll();
    } catch (e) {
      // Still clear local data even if there's an error
      await HiveStorageService.clearAll();
      rethrow;
    }
  }

  // Clear auth data (useful for forced logout)
  Future<void> clearAuthData() async {
    await HiveStorageService.clearAll();
  }

  // Update user profile (if you have this endpoint)
  Future<void> updateUserProfile({String? name, String? email}) async {
    // Implementation depends on your backend API
    // This is a placeholder for future functionality
  }

  // Refresh auth token (if you have refresh token mechanism)
  Future<String?> refreshAuthToken() async {
    // Implementation depends on your backend API
    // This is a placeholder for future functionality
    return null;
  }
}
