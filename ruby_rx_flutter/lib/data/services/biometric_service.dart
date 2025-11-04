import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter/services.dart';

class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if biometric authentication is available on the device
  static Future<bool> isBiometricAvailable() async {
    try {
      final bool isAvailable = await _localAuth.isDeviceSupported();
      final bool canCheck = await _localAuth.canCheckBiometrics;
      return isAvailable && canCheck;
    } catch (e) {
      return false;
    }
  }

  /// Get list of available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Check if specific biometric types are available
  static Future<bool> hasFingerprintSupport() async {
    final List<BiometricType> availableBiometrics =
        await getAvailableBiometrics();
    return availableBiometrics.contains(BiometricType.fingerprint);
  }

  static Future<bool> hasFaceIdSupport() async {
    final List<BiometricType> availableBiometrics =
        await getAvailableBiometrics();
    return availableBiometrics.contains(BiometricType.face);
  }

  /// Get appropriate biometric type name for display
  static Future<String> getBiometricTypeName() async {
    final List<BiometricType> availableBiometrics =
        await getAvailableBiometrics();

    if (availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (availableBiometrics.contains(BiometricType.iris)) {
      return 'Iris';
    } else {
      return 'Biometric';
    }
  }

  /// Authenticate using biometrics
  static Future<BiometricAuthResult> authenticateWithBiometrics({
    String reason = 'Please verify your identity to continue',
  }) async {
    try {
      final bool isAvailable = await isBiometricAvailable();

      if (!isAvailable) {
        return BiometricAuthResult(
          success: false,
          errorMessage:
              'Biometric authentication is not available on this device',
          errorType: BiometricErrorType.notAvailable,
        );
      }

      // Try biometric authentication with proper settings
      try {
        print('BiometricService: Attempting biometric authentication...');
        final bool didAuthenticate = await _localAuth.authenticate(
          localizedReason: reason,
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );

        if (didAuthenticate) {
          print('BiometricService: Authentication succeeded');
          return BiometricAuthResult(success: true);
        } else {
          print('BiometricService: Authentication cancelled by user');
          return BiometricAuthResult(
            success: false,
            errorMessage: 'Authentication was cancelled',
            errorType: BiometricErrorType.userCancel,
          );
        }
      } on PlatformException catch (e) {
        print(
          'BiometricService: Authentication failed with exception: ${e.message}',
        );

        // If still getting FragmentActivity error, try with device credentials as fallback
        if (e.message?.contains('FragmentActivity') == true) {
          print(
            'BiometricService: FragmentActivity error detected, trying device credentials fallback...',
          );

          try {
            final bool didAuthenticate = await _localAuth.authenticate(
              localizedReason: reason,
              options: const AuthenticationOptions(
                biometricOnly: false, // Allow device PIN/pattern as fallback
                stickyAuth: true,
              ),
            );

            if (didAuthenticate) {
              print(
                'BiometricService: Device credentials authentication succeeded',
              );
              return BiometricAuthResult(success: true);
            } else {
              print(
                'BiometricService: Device credentials authentication cancelled',
              );
              return BiometricAuthResult(
                success: false,
                errorMessage: 'Authentication was cancelled',
                errorType: BiometricErrorType.userCancel,
              );
            }
          } catch (fallbackError) {
            print(
              'BiometricService: Device credentials fallback also failed: $fallbackError',
            );
            return BiometricAuthResult(
              success: false,
              errorMessage:
                  'Unable to complete biometric authentication. Please restart the app and try again.',
              errorType: BiometricErrorType.unknown,
            );
          }
        } else {
          // Handle other platform exceptions
          return _handlePlatformException(e);
        }
      }
    } on PlatformException catch (e) {
      return _handlePlatformException(e);
    } catch (e) {
      return BiometricAuthResult(
        success: false,
        errorMessage: 'An unexpected error occurred: ${e.toString()}',
        errorType: BiometricErrorType.unknown,
      );
    }
  }

  /// Handle platform-specific exceptions
  static BiometricAuthResult _handlePlatformException(PlatformException e) {
    switch (e.code) {
      case auth_error.notAvailable:
        return BiometricAuthResult(
          success: false,
          errorMessage: 'Biometric authentication is not available',
          errorType: BiometricErrorType.notAvailable,
        );
      case auth_error.notEnrolled:
        return BiometricAuthResult(
          success: false,
          errorMessage:
              'No biometrics enrolled. Please set up fingerprint or face recognition in your device settings',
          errorType: BiometricErrorType.notEnrolled,
        );
      case auth_error.lockedOut:
        return BiometricAuthResult(
          success: false,
          errorMessage:
              'Too many failed attempts. Biometric authentication is temporarily locked',
          errorType: BiometricErrorType.lockedOut,
        );
      case auth_error.permanentlyLockedOut:
        return BiometricAuthResult(
          success: false,
          errorMessage:
              'Biometric authentication is permanently locked. Please use device password',
          errorType: BiometricErrorType.permanentlyLockedOut,
        );
      default:
        // Handle FragmentActivity error specifically
        if (e.message?.contains('FragmentActivity') == true) {
          return BiometricAuthResult(
            success: false,
            errorMessage:
                'Biometric authentication setup issue. Please restart the app and try again.',
            errorType: BiometricErrorType.unknown,
          );
        }
        return BiometricAuthResult(
          success: false,
          errorMessage: 'Authentication failed: ${e.message}',
          errorType: BiometricErrorType.unknown,
        );
    }
  }
}

/// Result class for biometric authentication
class BiometricAuthResult {
  final bool success;
  final String? errorMessage;
  final BiometricErrorType? errorType;

  BiometricAuthResult({
    required this.success,
    this.errorMessage,
    this.errorType,
  });
}

/// Enum for different types of biometric authentication errors
enum BiometricErrorType {
  notAvailable,
  notEnrolled,
  lockedOut,
  permanentlyLockedOut,
  userCancel,
  userFallback,
  unknown,
}
