import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/auth_state.dart';
import '../models/message_state.dart';
import '../routes/app_routes.dart';
import '../data/repositories/auth_repository.dart';
import '../data/models/api_models.dart';
import '../data/services/hive_storage_service.dart';
import '../data/services/biometric_service.dart';
import '../utils/navigation_helper.dart';

class AuthController extends GetxController {
  // Repository instance
  final AuthRepository _authRepository = AuthRepository();

  // Observable variables
  final Rx<UserModel> currentUser = UserModel().obs;
  final Rx<AuthState> authState = AuthState().obs;
  final Rx<MessageState> messageState = MessageState.clear().obs;

  // Form controllers
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  final pinController = TextEditingController();
  final confirmPinController = TextEditingController();
  final forgotPinEmailController = TextEditingController();

  // Observable form states
  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  final canNavigateBack = true.obs;
  final canNavigateForward = false.obs;
  final pinLength = 0.obs; // Add reactive PIN length

  // Granular loading states
  final isSendingOtp = false.obs;
  final isVerifyingOtp = false.obs;
  final isResendingOtp = false.obs;
  final isValidatingInput = false.obs;

  // OTP related variables
  final currentPhoneNumber = ''.obs;
  final otpSentTime = 0.obs;
  final canResendOtp = true.obs;
  final resendCountdown = 0.obs;

  // Biometric authentication variables
  final biometricAvailable = false.obs;
  final biometricTypeName = 'Biometric'.obs;
  final biometricEnabled =
      false.obs; // User's biometric preference from profile settings

  // Error handling
  final lastError = Rxn<String>();
  final lastErrorType = Rxn<ErrorType>();

  // Controller initialization state
  final isControllerReady = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeController();
    _setupTextControllerListeners();
  }

  void _setupTextControllerListeners() {
    // Listen to PIN controller changes and update reactive pinLength
    pinController.addListener(() {
      pinLength.value = pinController.text.length;
    });
  }

  Future<void> _initializeController() async {
    try {
      await _initializeStorageService();
      await _checkAndLoadUserData();
      await _checkBiometricAvailability();

      // Mark controller as ready after initialization
      WidgetsBinding.instance.addPostFrameCallback((_) {
        isControllerReady.value = true;
      });
    } catch (e) {
      print('Error initializing AuthController: $e');
      // Still mark as ready to prevent blocking
      isControllerReady.value = true;
    }
  }

  /// Public method to refresh authentication status and user data
  Future<void> refreshAuthStatus() async {
    await _checkAndLoadUserData();
  }

  /// Check authentication status from storage and load user data
  Future<void> _checkAndLoadUserData() async {
    try {
      print('🔍 Checking authentication status...');

      // Check if user is logged in
      final isLoggedIn = HiveStorageService.getLoginStatus();
      final hasAuthToken = HiveStorageService.getAuthToken() != null;
      final userData = HiveStorageService.getUserData();

      print('🔍 Login status: $isLoggedIn');
      print('🔍 Has auth token: $hasAuthToken');
      print('🔍 User data exists: ${userData != null}');

      if (isLoggedIn && hasAuthToken && userData != null) {
        // Load user data from storage
        currentUser.value = UserModel.fromJson(userData);
        authState.value = AuthState(status: AuthStatus.authenticated);

        print('✅ User authenticated and loaded: ${currentUser.value.id}');
        print('👤 User: ${currentUser.value.displayName}');
      } else {
        // User is not authenticated
        currentUser.value = UserModel();
        authState.value = AuthState(status: AuthStatus.unauthenticated);

        print('❌ User not authenticated');
      }
    } catch (e) {
      print('❌ Error checking auth status: $e');
      // Set to unauthenticated state on error
      currentUser.value = UserModel();
      authState.value = AuthState(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final isAvailable = await isBiometricAvailable();
      biometricAvailable.value = isAvailable;

      if (isAvailable) {
        final typeName = await getBiometricTypeName();
        biometricTypeName.value = typeName;
      }

      // Also check user's biometric preference from storage
      final userPreference = HiveStorageService.getBiometricEnabled();
      biometricEnabled.value = userPreference;
    } catch (e) {
      print('Error checking biometric availability: $e');
      biometricAvailable.value = false;
      biometricEnabled.value = false;
    }
  }

  Future<void> _initializeStorageService() async {
    await HiveStorageService.init();
  }

  @override
  void onClose() {
    emailController.dispose();
    phoneController.dispose();
    otpController.dispose();
    pinController.dispose();
    confirmPinController.dispose();
    forgotPinEmailController.dispose();
    super.onClose();
  }

  // Utility methods for error handling and user feedback
  void _setErrorMessage(String message, {ErrorType? errorType}) {
    lastError.value = message;
    lastErrorType.value = errorType ?? ErrorType.unknown;
    messageState.value = MessageState.error(message, errorType: errorType);
  }

  void _setSuccessMessage(String message) {
    messageState.value = MessageState.success(message);
  }

  void _setInfoMessage(String message) {
    messageState.value = MessageState.info(message);
  }

  ErrorType _categorizeError(dynamic error) {
    if (error is ApiError) {
      if (error.statusCode != null) {
        if (error.statusCode! >= 400 && error.statusCode! < 500) {
          if (error.statusCode == 401 || error.statusCode == 403) {
            return ErrorType.authentication;
          }
          return ErrorType.validation;
        } else if (error.statusCode! >= 500) {
          return ErrorType.server;
        }
      }
      if (error.code == 'NETWORK_ERROR') {
        return ErrorType.network;
      }
    }

    String errorMessage = error.toString().toLowerCase();
    if (errorMessage.contains('network') ||
        errorMessage.contains('connection')) {
      return ErrorType.network;
    } else if (errorMessage.contains('timeout')) {
      return ErrorType.timeout;
    } else if (errorMessage.contains('invalid') ||
        errorMessage.contains('validation')) {
      return ErrorType.validation;
    } else if (errorMessage.contains('unauthorized') ||
        errorMessage.contains('forbidden')) {
      return ErrorType.authentication;
    }

    return ErrorType.unknown;
  }

  String _getUserFriendlyErrorMessage(dynamic error, ErrorType errorType) {
    switch (errorType) {
      case ErrorType.network:
        return 'Please check your internet connection and try again.';
      case ErrorType.timeout:
        return 'Request timed out. Please try again.';
      case ErrorType.server:
        return 'Server is temporarily unavailable. Please try again later.';
      case ErrorType.authentication:
        if (error is ApiError) {
          return error.message;
        }
        return 'Authentication failed. Please try again.';
      case ErrorType.validation:
        if (error is ApiError) {
          return error.message;
        }
        return 'Please check your input and try again.';
      case ErrorType.unknown:
        if (error is ApiError) {
          return error.message;
        }
        return error.toString();
    }
  }

  void clearError() {
    lastError.value = null;
    lastErrorType.value = null;
    authState.value = authState.value.copyWith(error: null);
    messageState.value = MessageState.clear();
  }

  void clearMessage() {
    messageState.value = MessageState.clear();
  }

  // Check if user is already authenticated
  Future<void> checkAuthStatus() async {
    try {
      final isLoggedIn = await _authRepository.isLoggedIn();
      if (isLoggedIn) {
        final user = await _authRepository.getStoredUser();
        if (user != null) {
          currentUser.value = user;
          authState.value = AuthState(status: AuthStatus.authenticated);
          return;
        }
      }
      authState.value = AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      authState.value = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> loginWithPhone(String phone) async {
    try {
      // Clear any previous errors
      clearError();

      // Validate input
      if (phone.isEmpty) {
        _setErrorMessage(
          'Please enter your phone number',
          errorType: ErrorType.validation,
        );
        return;
      }

      // Enhanced phone validation
      String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
      if (cleanPhone.length < 10) {
        _setErrorMessage(
          'Please enter a valid 10-digit phone number',
          errorType: ErrorType.validation,
        );
        return;
      }

      isSendingOtp.value = true;
      isLoading.value = true;
      authState.value = AuthState(status: AuthStatus.loading);

      // Validate phone number format
      if (!cleanPhone.startsWith('+')) {
        cleanPhone = '+91$cleanPhone'; // Add India country code if not present
      }

      final response = await _authRepository.sendPatientLoginOtp(cleanPhone);

      if (response.isSuccess) {
        // OTP sent successfully
        currentPhoneNumber.value = cleanPhone;
        otpSentTime.value = DateTime.now().millisecondsSinceEpoch;
        canResendOtp.value = false;

        // Start resend timer (60 seconds)
        _startResendTimer();

        authState.value = AuthState(
          status: AuthStatus.otpRequired,
          message: response.message ?? 'OTP sent successfully',
        );

        _setSuccessMessage('OTP sent successfully via WhatsApp');

        // Use post frame callback to ensure navigation happens after current build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.toNamed(AppRoutes.otpVerify, arguments: {'phone': cleanPhone});
        });
      } else {
        // Handle specific error codes for patient authentication
        final errorCode =
            response.data?.toString().contains('PATIENT_NOT_FOUND') ?? false;

        if (errorCode) {
          authState.value = AuthState(
            status: AuthStatus.unauthenticated,
            message: 'Phone number not registered. Please register first.',
          );
          _setErrorMessage(
            'Phone number not registered. Would you like to register?',
            errorType: ErrorType.validation,
          );

          // Use post frame callback for navigation
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Navigate to registration with phone number
            Get.toNamed(AppRoutes.register, arguments: {'phone': cleanPhone});
          });
        } else {
          throw Exception(response.message ?? 'Failed to send OTP');
        }
      }
    } on ApiError catch (e) {
      final errorType = _categorizeError(e);
      final userMessage = _getUserFriendlyErrorMessage(e, errorType);

      authState.value = AuthState(
        status: AuthStatus.unauthenticated,
        error: e.message,
      );

      _setErrorMessage(userMessage, errorType: errorType);
    } catch (e) {
      final errorType = _categorizeError(e);
      final userMessage = _getUserFriendlyErrorMessage(e, errorType);

      authState.value = AuthState(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );

      _setErrorMessage(userMessage, errorType: errorType);
    } finally {
      isSendingOtp.value = false;
      isLoading.value = false;
    }
  }

  // OTP Verification
  Future<void> verifyOtp(String otp) async {
    // Get phone number at method level for access in catch blocks
    final phone = currentPhoneNumber.value.isNotEmpty
        ? currentPhoneNumber.value
        : Get.arguments?['phone'] ?? '';

    try {
      // Clear any previous errors
      clearError();

      // Validate OTP input
      if (otp.isEmpty) {
        _setErrorMessage(
          'Please enter the OTP',
          errorType: ErrorType.validation,
        );
        return;
      }

      if (otp.length != 4) {
        _setErrorMessage(
          'Please enter a valid 4-digit OTP',
          errorType: ErrorType.validation,
        );
        return;
      }

      if (!RegExp(r'^[0-9]+$').hasMatch(otp)) {
        _setErrorMessage(
          'OTP should contain only numbers',
          errorType: ErrorType.validation,
        );
        return;
      }

      isVerifyingOtp.value = true;
      isLoading.value = true;
      authState.value = AuthState(status: AuthStatus.loading);

      if (phone.isEmpty) {
        throw Exception('Phone number not found. Please try again.');
      }

      final response = await _authRepository.verifyPhoneOtp(phone, otp);

      if (response.isSuccess) {
        if (response.data != null && response.data!.token.isNotEmpty) {
          // EXISTING USER: Token returned - user exists and is logged in
          final userData = response.data!;

          // Store authentication data in Hive
          await HiveStorageService.setAuthToken(userData.token);
          await HiveStorageService.setLoginStatus(true);
          await HiveStorageService.setPhoneNumber(phone);
          await HiveStorageService.setPinSetupStatus(
            userData.patientInfo.hasPinSetup,
          );

          // Create user model from response data
          currentUser.value = UserModel(
            id: userData.patientInfo.id,
            phone: userData.patientInfo.phone,
            name:
                "${userData.patientInfo.firstName} ${userData.patientInfo.lastName}",
            email: userData.patientInfo.email,
            firstName: userData.patientInfo.firstName,
            lastName: userData.patientInfo.lastName,
            isLoggedIn: true,
            hasPinSetup: userData.patientInfo.hasPinSetup,
          );

          // Save user data to local storage for later use (like manual prescription entry)
          await HiveStorageService.setUserData(currentUser.value.toJson());

          if (currentUser.value.hasPinSetup) {
            // Existing user with PIN - navigate to PIN entry
            authState.value = AuthState(
              status: AuthStatus.pinRequired,
              message: 'Please enter your PIN to continue',
            );

            _setSuccessMessage('Welcome back! Please enter your PIN.');

            WidgetsBinding.instance.addPostFrameCallback((_) {
              Get.offAllNamed(AppRoutes.pinEntry);
            });
          } else {
            // Existing user without PIN - navigate to PIN setup
            authState.value = AuthState(
              status: AuthStatus.pinRequired,
              message: 'Please set up your security PIN.',
            );

            _setSuccessMessage('Please set up your security PIN.');

            WidgetsBinding.instance.addPostFrameCallback((_) {
              Get.offAllNamed(AppRoutes.setupPin);
            });
          }
        } else {
          // NEW USER: No token returned - user needs to register
          authState.value = AuthState(
            status: AuthStatus.unauthenticated,
            message: 'OTP verified. Please complete your registration.',
          );

          _setSuccessMessage(
            'OTP verified! Please complete your registration.',
          );

          // Store phone number for registration process
          currentPhoneNumber.value = phone;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.offAllNamed(
              AppRoutes.registrationForm,
              arguments: {
                'phone': phone,
                'otpVerified': true,
                'isNewUser': true,
              },
            );
          });
        }
      } else {
        throw Exception(response.message ?? 'Invalid OTP. Please try again.');
      }
    } on ApiError catch (e) {
      final errorType = _categorizeError(e);
      final userMessage = _getUserFriendlyErrorMessage(e, errorType);

      authState.value = AuthState(
        status: AuthStatus.otpRequired,
        error: e.message,
      );

      _setErrorMessage(userMessage, errorType: errorType);
    } catch (e) {
      final errorType = _categorizeError(e);
      final userMessage = _getUserFriendlyErrorMessage(e, errorType);

      authState.value = AuthState(
        status: AuthStatus.otpRequired,
        error: e.toString(),
      );

      _setErrorMessage(userMessage, errorType: errorType);
    } finally {
      isVerifyingOtp.value = false;
      isLoading.value = false;
    }
  }

  // Resend OTP
  Future<void> resendOtp() async {
    try {
      if (!canResendOtp.value) {
        _setInfoMessage(
          'Please wait ${resendCountdown.value} seconds before requesting another OTP',
        );
        return;
      }

      // Clear any previous errors
      clearError();

      isResendingOtp.value = true;
      final phone = currentPhoneNumber.value;

      if (phone.isEmpty) {
        throw Exception('Phone number not found. Please try again.');
      }

      final response = await _authRepository.resendPatientLoginOtp(phone);

      if (response.isSuccess) {
        otpSentTime.value = DateTime.now().millisecondsSinceEpoch;
        canResendOtp.value = false;
        _startResendTimer();

        _setSuccessMessage('OTP resent successfully via WhatsApp');
      } else {
        throw Exception(response.message ?? 'Failed to resend OTP');
      }
    } on ApiError catch (e) {
      final errorType = _categorizeError(e);
      final userMessage = _getUserFriendlyErrorMessage(e, errorType);
      _setErrorMessage(userMessage, errorType: errorType);
    } catch (e) {
      final errorType = _categorizeError(e);
      final userMessage = _getUserFriendlyErrorMessage(e, errorType);
      _setErrorMessage(userMessage, errorType: errorType);
    } finally {
      isResendingOtp.value = false;
    }
  }

  // Timer for OTP resend with countdown
  void _startResendTimer() {
    resendCountdown.value = 60;

    // Update countdown every second
    for (int i = 59; i >= 0; i--) {
      Future.delayed(Duration(seconds: 60 - i), () {
        if (resendCountdown.value > 0) {
          resendCountdown.value = i;
        }
      });
    }

    // Enable resend after 60 seconds
    Future.delayed(const Duration(seconds: 60), () {
      canResendOtp.value = true;
      resendCountdown.value = 0;
    });
  }

  // Check if user exists
  Future<bool> checkUserExists(String phone) async {
    // Simulate API call to check user existence
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock: Return false for demo (user doesn't exist)
    // In real app, this would check against your backend
    return false;
  }

  // Register new user using the new registration endpoint
  Future<void> registerUserWithNewEndpoint({
    required String phoneNumber,
    required String firstName,
    required String lastName,
    required String email,
    required DateTime dateOfBirth,
    String? address,
  }) async {
    try {
      // Clear any previous errors
      clearError();

      isLoading.value = true;

      final response = await _authRepository.registerPatient(
        phoneNumber: phoneNumber,
        firstName: firstName,
        lastName: lastName,
        email: email,
        dateOfBirth: dateOfBirth,
        address: address,
      );

      if (response.isSuccess && response.data != null) {
        final registrationData = response.data!;

        // Show success message
        _setSuccessMessage('Registration successful! Please set up your PIN.');

        // Store phone number for PIN setup and persistence
        currentPhoneNumber.value = phoneNumber;
        await HiveStorageService.setPhoneNumber(phoneNumber);

        // Navigate to PIN setup with registration context
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.offAllNamed(
            AppRoutes.setupPin,
            arguments: {
              'phone': phoneNumber,
              'registrationComplete': true,
              'patientId': registrationData.patient.id,
              'firstName': firstName,
              'lastName': lastName,
              'email': email,
            },
          );
        });
      } else {
        throw Exception(response.message ?? 'Registration failed');
      }
    } on ApiError catch (e) {
      // Handle specific API errors
      String errorMessage = 'Registration failed. Please try again.';

      if (e.message.contains('PHONE_EXISTS') ||
          e.message.contains('already registered')) {
        errorMessage =
            'This phone number is already registered. Please login instead.';
      } else if (e.message.contains('EMAIL_EXISTS') ||
          e.message.contains('email already')) {
        errorMessage =
            'This email address is already registered. Please use a different email or login.';
      } else if (e.statusCode == 400) {
        errorMessage = e.message.isNotEmpty
            ? e.message
            : 'Please check your information and try again.';
      } else {
        final errorType = _categorizeError(e);
        errorMessage = _getUserFriendlyErrorMessage(e, errorType);
      }

      _setErrorMessage(errorMessage, errorType: _categorizeError(e));
    } catch (e) {
      // Handle generic errors
      String errorMessage = 'Registration failed. Please try again.';

      if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMessage =
            'Network error. Please check your connection and try again.';
      }

      _setErrorMessage(errorMessage, errorType: _categorizeError(e));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> setupPin(String pin, String confirmPin) async {
    try {
      isLoading.value = true;
      clearError();

      if (pin != confirmPin) {
        _setErrorMessage('PINs do not match', errorType: ErrorType.validation);
        return;
      }

      if (pin.length != 4 || !RegExp(r'^[0-9]+$').hasMatch(pin)) {
        _setErrorMessage(
          'PIN must be 4 digits',
          errorType: ErrorType.validation,
        );
        return;
      }

      // Call the backend API to setup PIN
      final response = await _authRepository.setupPin(pin);

      if (response.isSuccess && response.data != null) {
        // Store PIN securely in Hive after successful backend response
        await HiveStorageService.setAppPin(pin);
        await HiveStorageService.setPinSetupStatus(true);

        // Update user model and save to storage
        final updatedUser = currentUser.value.copyWith(hasPinSetup: true);
        currentUser.value = updatedUser;
        await HiveStorageService.setUserData(updatedUser.toJson());

        authState.value = AuthState(status: AuthStatus.authenticated);

        _setSuccessMessage('PIN setup completed successfully!');

        // Use post frame callback to ensure navigation happens after current build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          NavigationHelper.navigateToHome();
        });
      } else {
        throw Exception(response.message ?? 'Failed to setup PIN');
      }
    } on ApiError catch (e) {
      final errorType = _categorizeError(e);
      final userMessage = _getUserFriendlyErrorMessage(e, errorType);
      _setErrorMessage(userMessage, errorType: errorType);
    } catch (e) {
      final errorType = _categorizeError(e);
      final userMessage = _getUserFriendlyErrorMessage(e, errorType);
      _setErrorMessage(userMessage, errorType: errorType);
    } finally {
      isLoading.value = false;
    }
  }

  // PIN Verification for app access
  Future<bool> verifyPin(String pin) async {
    try {
      if (pin.isEmpty || pin.length != 4) {
        _setErrorMessage(
          'Please enter a valid 4-digit PIN',
          errorType: ErrorType.validation,
        );
        return false;
      }

      // Check if PIN is stored locally first
      final storedPin = HiveStorageService.getAppPin();

      if (storedPin != null) {
        // Local PIN verification
        if (pin == storedPin) {
          await _handleSuccessfulPinVerification();
          return true;
        } else {
          _setErrorMessage(
            'Incorrect PIN. Please try again.',
            errorType: ErrorType.authentication,
          );
          return false;
        }
      } else {
        // PIN not stored locally - verify against backend and store locally if successful
        return await _verifyPinWithBackendAndStore(pin);
      }
    } catch (e) {
      _setErrorMessage(
        'Failed to verify PIN. Please try again.',
        errorType: ErrorType.unknown,
      );
      return false;
    }
  }

  // Helper method to handle successful PIN verification
  Future<void> _handleSuccessfulPinVerification() async {
    // Update last login time
    await HiveStorageService.setLastLoginTime(DateTime.now());

    // Set session expiry (24 hours from now)
    final sessionExpiry = DateTime.now().add(const Duration(hours: 24));
    await HiveStorageService.setSessionExpiry(sessionExpiry);

    authState.value = AuthState(status: AuthStatus.authenticated);
    _setSuccessMessage('Welcome back!');
  }

  // Helper method to verify PIN with backend and store locally
  Future<bool> _verifyPinWithBackendAndStore(String pin) async {
    try {
      isLoading.value = true;

      final phone = currentUser.value.phone ?? '';
      if (phone.isEmpty) {
        _setErrorMessage(
          'Phone number not found. Please login again.',
          errorType: ErrorType.authentication,
        );
        return false;
      }

      // Verify PIN with backend
      final response = await _authRepository.verifyPin(phone, pin);

      if (response.isSuccess) {
        // Store PIN locally for future offline verification
        await HiveStorageService.setAppPin(pin);
        await HiveStorageService.setPinSetupStatus(true);

        await _handleSuccessfulPinVerification();
        return true;
      } else {
        _setErrorMessage(
          'Incorrect PIN. Please try again.',
          errorType: ErrorType.authentication,
        );
        return false;
      }
    } on ApiError catch (e) {
      final errorType = _categorizeError(e);
      final userMessage = _getUserFriendlyErrorMessage(e, errorType);
      _setErrorMessage(userMessage, errorType: errorType);
      return false;
    } catch (e) {
      _setErrorMessage(
        'Failed to verify PIN. Please try again.',
        errorType: ErrorType.unknown,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Biometric Authentication Methods
  Future<bool> isBiometricAvailable() async {
    return await BiometricService.isBiometricAvailable();
  }

  Future<String> getBiometricTypeName() async {
    return await BiometricService.getBiometricTypeName();
  }

  // Method to update biometric preference (called from profile settings)
  Future<void> updateBiometricPreference(bool enabled) async {
    try {
      await HiveStorageService.setBiometricEnabled(enabled);
      biometricEnabled.value = enabled;
    } catch (e) {
      print('Error updating biometric preference: $e');
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      isLoading.value = true;

      final result = await BiometricService.authenticateWithBiometrics(
        reason: 'Please verify your identity to access the app',
      );

      if (result.success) {
        // Biometric authentication successful - update auth state and navigate to home
        await HiveStorageService.setLastLoginTime(DateTime.now());

        // Set session expiry (24 hours from now)
        final sessionExpiry = DateTime.now().add(const Duration(hours: 24));
        await HiveStorageService.setSessionExpiry(sessionExpiry);

        authState.value = AuthState(status: AuthStatus.authenticated);
        _setSuccessMessage('Biometric authentication successful!');

        // Navigate to home
        WidgetsBinding.instance.addPostFrameCallback((_) {
          NavigationHelper.navigateToHome();
        });

        return true;
      } else {
        // Handle biometric authentication failure
        if (result.errorType == BiometricErrorType.userCancel) {
          // User cancelled - don't show error message
          return false;
        } else if (result.errorType == BiometricErrorType.notEnrolled) {
          _setErrorMessage(
            'No biometric authentication set up. Please set up fingerprint or face recognition in your device settings.',
            errorType: ErrorType.authentication,
          );
        } else if (result.errorType == BiometricErrorType.notAvailable) {
          _setErrorMessage(
            'Biometric authentication is not available on this device.',
            errorType: ErrorType.authentication,
          );
        } else {
          _setErrorMessage(
            result.errorMessage ??
                'Biometric authentication failed. Please try again.',
            errorType: ErrorType.authentication,
          );
        }
        return false;
      }
    } catch (e) {
      _setErrorMessage(
        'Biometric authentication failed. Please try again.',
        errorType: ErrorType.unknown,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // PIN Verification with option to use biometrics first
  Future<bool> verifyPinWithBiometrics(
    String pin, {
    bool useBiometric = false,
  }) async {
    if (useBiometric) {
      final biometricAvailable = await isBiometricAvailable();
      if (biometricAvailable) {
        return await authenticateWithBiometrics();
      }
    }

    // Fallback to PIN verification
    return await verifyPin(pin);
  }

  // Check if PIN exists and is setup (based on actual Hive storage data)
  bool get isPinSetup {
    return HiveStorageService.getPinSetupStatus();
  }

  // Reset PIN with new PIN
  Future<void> resetPin(String newPin, String confirmPin) async {
    try {
      if (newPin != confirmPin) {
        _setErrorMessage('PINs do not match', errorType: ErrorType.validation);
        return;
      }

      if (newPin.length != 4 || !RegExp(r'^[0-9]+$').hasMatch(newPin)) {
        _setErrorMessage(
          'PIN must be 4 digits',
          errorType: ErrorType.validation,
        );
        return;
      }

      isLoading.value = true;

      // Store new PIN
      await HiveStorageService.setAppPin(newPin);
      await HiveStorageService.setPinSetupStatus(true);

      // Update user model
      final updatedUser = currentUser.value.copyWith(hasPinSetup: true);
      currentUser.value = updatedUser;
      await HiveStorageService.setUserData(updatedUser.toJson());

      _setSuccessMessage('PIN reset successfully!');

      // Use post frame callback to ensure navigation happens after current build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.back(); // Go back to previous screen
      });
    } catch (e) {
      _setErrorMessage(
        'Failed to reset PIN. Please try again.',
        errorType: ErrorType.unknown,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Change PIN (when user knows current PIN)
  Future<void> changePin(
    String currentPin,
    String newPin,
    String confirmPin,
  ) async {
    try {
      // Verify current PIN first
      final storedPin = HiveStorageService.getAppPin();
      if (storedPin == null || currentPin != storedPin) {
        _setErrorMessage(
          'Current PIN is incorrect',
          errorType: ErrorType.authentication,
        );
        return;
      }

      // Use resetPin method to set new PIN
      await resetPin(newPin, confirmPin);
    } catch (e) {
      _setErrorMessage(
        'Failed to change PIN. Please try again.',
        errorType: ErrorType.unknown,
      );
    }
  }

  // Clear PIN (for logout or reset)
  Future<void> clearPin() async {
    try {
      await HiveStorageService.clearAppPin();
      await HiveStorageService.setPinSetupStatus(false);

      // Update user model
      final updatedUser = currentUser.value.copyWith(hasPinSetup: false);
      currentUser.value = updatedUser;
      await HiveStorageService.setUserData(updatedUser.toJson());
    } catch (e) {
      // Silent failure for PIN clearing
    }
  }

  // Send OTP for forgot PIN
  Future<void> sendForgotPinOtp(String phoneNumber) async {
    try {
      // Clear any previous errors
      clearError();

      if (phoneNumber.isEmpty) {
        _setErrorMessage(
          'Please enter your phone number',
          errorType: ErrorType.validation,
        );
        return;
      }

      isLoading.value = true;
      authState.value = AuthState(status: AuthStatus.loading);

      // Validate and clean phone number
      String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      if (!cleanPhone.startsWith('+')) {
        cleanPhone = '+91$cleanPhone';
      }

      final response = await _authRepository.sendForgotPinOtp(cleanPhone);

      if (response.isSuccess) {
        currentPhoneNumber.value = cleanPhone;
        authState.value = AuthState(
          status: AuthStatus.otpSent,
          message: 'PIN reset OTP sent to your WhatsApp',
        );

        _setSuccessMessage('PIN reset OTP sent to your WhatsApp');

        // Use post frame callback to ensure navigation happens after current build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.toNamed('/forgot-pin-verify', arguments: {'phone': cleanPhone});
        });
      } else {
        throw Exception(response.message ?? 'Failed to send PIN reset OTP');
      }
    } on ApiError catch (e) {
      final errorType = _categorizeError(e);
      final userMessage = _getUserFriendlyErrorMessage(e, errorType);

      authState.value = AuthState(
        status: AuthStatus.unauthenticated,
        error: e.message,
      );

      _setErrorMessage(userMessage, errorType: errorType);
    } catch (e) {
      final errorType = _categorizeError(e);
      final userMessage = _getUserFriendlyErrorMessage(e, errorType);

      authState.value = AuthState(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );

      _setErrorMessage(userMessage, errorType: errorType);
    } finally {
      isLoading.value = false;
    }
  }

  // Verify OTP for forgot PIN
  Future<void> verifyForgotPinOtp(String phoneNumber, String otp) async {
    try {
      // Clear any previous errors
      clearError();

      if (otp.isEmpty || otp.length != 4) {
        _setErrorMessage(
          'Please enter a valid 4-digit OTP',
          errorType: ErrorType.validation,
        );
        return;
      }

      isLoading.value = true;
      authState.value = AuthState(status: AuthStatus.loading);

      final response = await _authRepository.verifyForgotPinOtp(
        phoneNumber,
        otp,
      );

      if (response.isSuccess && response.data != null) {
        authState.value = AuthState(
          status: AuthStatus.pinReset,
          message: 'OTP verified. You can now reset your PIN.',
        );

        _setSuccessMessage('OTP verified. You can now reset your PIN.');

        // Store reset token and navigate to PIN reset screen
        // Use post frame callback to ensure navigation happens after current build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.toNamed(
            '/reset-pin',
            arguments: {
              'phone': phoneNumber,
              'resetToken': response.data!.resetToken,
            },
          );
        });
      } else {
        throw Exception(response.message ?? 'Invalid OTP. Please try again.');
      }
    } on ApiError catch (e) {
      final errorType = _categorizeError(e);
      final userMessage = _getUserFriendlyErrorMessage(e, errorType);

      authState.value = AuthState(status: AuthStatus.otpSent, error: e.message);

      _setErrorMessage(userMessage, errorType: errorType);
    } catch (e) {
      final errorType = _categorizeError(e);
      final userMessage = _getUserFriendlyErrorMessage(e, errorType);

      authState.value = AuthState(
        status: AuthStatus.otpSent,
        error: e.toString(),
      );

      _setErrorMessage(userMessage, errorType: errorType);
    } finally {
      isLoading.value = false;
    }
  }

  // Forgot PIN (legacy email-based method - kept for compatibility)
  Future<void> forgotPin(String email) async {
    try {
      isLoading.value = true;

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      authState.value = AuthState(
        status: AuthStatus.unauthenticated,
        message: 'PIN reset instructions sent to $email',
      );

      // Use post frame callback to ensure navigation happens after current build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.toNamed(AppRoutes.login);
      });
    } catch (e) {
      authState.value = AuthState(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _authRepository.logout();
      currentUser.value = UserModel();
      authState.value = AuthState(status: AuthStatus.unauthenticated);

      // Use post frame callback to ensure navigation happens after current build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed(AppRoutes.login);
      });
    } catch (e) {
      // Still navigate to login even if logout API fails
      currentUser.value = UserModel();
      authState.value = AuthState(status: AuthStatus.unauthenticated);

      // Use post frame callback to ensure navigation happens after current build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed(AppRoutes.login);
      });
    }
  }

  // Navigation helpers
  void goBack() {
    NavigationHelper.goBack(fallbackRoute: AppRoutes.login);
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  // Enhanced validation helpers
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove all non-digit characters except +
    String cleanPhone = value.replaceAll(RegExp(r'[^\d+]'), '');

    // Check if it's a valid Indian phone number
    if (cleanPhone.startsWith('+91')) {
      cleanPhone = cleanPhone.substring(3);
    } else if (cleanPhone.startsWith('+')) {
      return 'Only Indian phone numbers (+91) are supported';
    }

    if (cleanPhone.length != 10) {
      return 'Phone number must be 10 digits';
    }

    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(cleanPhone)) {
      return 'Enter a valid Indian mobile number';
    }

    return null;
  }

  String? validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }
    if (value.length != 4) {
      return 'OTP must be 4 digits';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'OTP should contain only numbers';
    }
    return null;
  }

  String? validatePin(String? value) {
    if (value == null || value.isEmpty) {
      return 'PIN is required';
    }
    if (value.length != 4) {
      return 'PIN must be 4 digits';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'PIN should contain only numbers';
    }
    return null;
  }

  // Input formatting helpers
  String formatPhoneNumber(String input) {
    // Remove all non-digit characters except +
    String cleanPhone = input.replaceAll(RegExp(r'[^\d+]'), '');

    // Add +91 prefix if not present
    if (!cleanPhone.startsWith('+')) {
      cleanPhone = '+91$cleanPhone';
    }

    return cleanPhone;
  }

  String formatPhoneForDisplay(String phone) {
    if (phone.startsWith('+91')) {
      String number = phone.substring(3);
      if (number.length == 10) {
        return '+91 ${number.substring(0, 5)} ${number.substring(5)}';
      }
    }
    return phone;
  }
}
