import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

class HiveStorageService {
  // Box names
  static const String _authBoxName = 'auth_box';
  static const String _userBoxName = 'user_box';
  static const String _appBoxName = 'app_box';

  // Box keys
  static const String _authTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _appPinKey = 'app_pin';
  static const String _userDataKey = 'user_data';
  static const String _phoneNumberKey = 'phone_number';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _pinSetupKey = 'pin_setup_status';
  static const String _resetTokenKey = 'reset_token';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _lastLoginTimeKey = 'last_login_time';
  static const String _sessionExpiryKey = 'session_expiry';
  static const String _tutorialCompletedKey = 'tutorial_completed';
  static const String _firstAppLaunchKey = 'first_app_launch';

  // Hive boxes
  static Box<String>? _authBox;
  static Box<dynamic>? _userBox;
  static Box<dynamic>? _appBox;

  // Initialize Hive and open boxes
  static Future<void> init() async {
    try {
      // Initialize Hive
      await Hive.initFlutter();

      // Open boxes
      _authBox = await Hive.openBox<String>(_authBoxName);
      _userBox = await Hive.openBox(_userBoxName);
      _appBox = await Hive.openBox(_appBoxName);

      if (kDebugMode) {
        print('HiveStorageService: Initialization completed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Initialization error: $e');
      }
      rethrow;
    }
  }

  // Auth Token Methods
  static Future<void> setAuthToken(String token) async {
    try {
      await _authBox?.put(_authTokenKey, token);
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error setting auth token: $e');
      }
      rethrow;
    }
  }

  static String? getAuthToken() {
    try {
      return _authBox?.get(_authTokenKey);
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error getting auth token: $e');
      }
      return null;
    }
  }

  static Future<void> clearAuthToken() async {
    try {
      await _authBox?.delete(_authTokenKey);
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error clearing auth token: $e');
      }
    }
  }

  // Refresh Token Methods
  static Future<void> setRefreshToken(String token) async {
    try {
      await _authBox?.put(_refreshTokenKey, token);
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error setting refresh token: $e');
      }
      rethrow;
    }
  }

  static String? getRefreshToken() {
    try {
      return _authBox?.get(_refreshTokenKey);
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error getting refresh token: $e');
      }
      return null;
    }
  }

  static Future<void> clearRefreshToken() async {
    try {
      await _authBox?.delete(_refreshTokenKey);
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error clearing refresh token: $e');
      }
    }
  }

  // App PIN Methods
  static Future<void> setAppPin(String pin) async {
    try {
      await _appBox?.put(_appPinKey, pin);
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error setting app PIN: $e');
      }
      rethrow;
    }
  }

  static String? getAppPin() {
    try {
      return _appBox?.get(_appPinKey);
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error getting app PIN: $e');
      }
      return null;
    }
  }

  static Future<void> clearAppPin() async {
    try {
      await _appBox?.delete(_appPinKey);
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error clearing app PIN: $e');
      }
    }
  }

  // User Data Methods
  static Future<void> setUserData(Map<String, dynamic> userData) async {
    try {
      final userDataString = jsonEncode(userData);
      await _userBox?.put(_userDataKey, userDataString);
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error setting user data: $e');
      }
      rethrow;
    }
  }

  static Map<String, dynamic>? getUserData() {
    try {
      final userDataString = _userBox?.get(_userDataKey);
      if (userDataString != null && userDataString is String) {
        try {
          return jsonDecode(userDataString) as Map<String, dynamic>;
        } catch (e) {
          if (kDebugMode) {
            print('HiveStorageService: Error decoding user data: $e');
          }
          // Clear corrupted data
          clearUserData();
          return null;
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error getting user data: $e');
      }
      return null;
    }
  }

  static Future<void> clearUserData() async {
    try {
      await _userBox?.delete(_userDataKey);
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error clearing user data: $e');
      }
    }
  }

  // Phone Number Methods
  static Future<void> setPhoneNumber(String phoneNumber) async {
    try {
      await _userBox?.put(_phoneNumberKey, phoneNumber);
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error setting phone number: $e');
      }
      rethrow;
    }
  }

  static String? getPhoneNumber() {
    try {
      return _userBox?.get(_phoneNumberKey);
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error getting phone number: $e');
      }
      return null;
    }
  }

  static Future<void> clearPhoneNumber() async {
    try {
      await _userBox?.delete(_phoneNumberKey);
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error clearing phone number: $e');
      }
    }
  }

  // Login Status Methods
  static Future<void> setLoginStatus(bool isLoggedIn) async {
    try {
      await _appBox?.put(_isLoggedInKey, isLoggedIn);
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error setting login status: $e');
      }
      rethrow;
    }
  }

  static bool getLoginStatus() {
    try {
      return _appBox?.get(_isLoggedInKey, defaultValue: false) ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error getting login status: $e');
      }
      return false;
    }
  }

  static Future<void> clearLoginStatus() async {
    try {
      await _appBox?.delete(_isLoggedInKey);
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error clearing login status: $e');
      }
    }
  }

  // PIN Setup Status Methods
  static Future<void> setPinSetupStatus(bool isSetup) async {
    try {
      await _appBox?.put(_pinSetupKey, isSetup);
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error setting PIN setup status: $e');
      }
      rethrow;
    }
  }

  static bool getPinSetupStatus() {
    try {
      return _appBox?.get(_pinSetupKey, defaultValue: false) ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error getting PIN setup status: $e');
      }
      return false;
    }
  }

  static Future<void> clearPinSetupStatus() async {
    try {
      await _appBox?.delete(_pinSetupKey);
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error clearing PIN setup status: $e');
      }
    }
  }

  // Reset Token Methods
  static Future<void> setResetToken(String token) async {
    try {
      await _authBox?.put(_resetTokenKey, token);
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error setting reset token: $e');
      }
      rethrow;
    }
  }

  static String? getResetToken() {
    try {
      return _authBox?.get(_resetTokenKey);
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error getting reset token: $e');
      }
      return null;
    }
  }

  static Future<void> clearResetToken() async {
    try {
      await _authBox?.delete(_resetTokenKey);
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error clearing reset token: $e');
      }
    }
  }

  // Biometric Settings Methods
  static Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _appBox?.put(_biometricEnabledKey, enabled);
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error setting biometric status: $e');
      }
      rethrow;
    }
  }

  static bool getBiometricEnabled() {
    try {
      return _appBox?.get(_biometricEnabledKey, defaultValue: false) ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error getting biometric status: $e');
      }
      return false;
    }
  }

  // Session Management Methods
  static Future<void> setLastLoginTime(DateTime dateTime) async {
    try {
      await _appBox?.put(_lastLoginTimeKey, dateTime.millisecondsSinceEpoch);
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error setting last login time: $e');
      }
      rethrow;
    }
  }

  static DateTime? getLastLoginTime() {
    try {
      final timestamp = _appBox?.get(_lastLoginTimeKey);
      if (timestamp != null && timestamp is int) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error getting last login time: $e');
      }
      return null;
    }
  }

  static Future<void> setSessionExpiry(DateTime expiry) async {
    try {
      await _appBox?.put(_sessionExpiryKey, expiry.millisecondsSinceEpoch);
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error setting session expiry: $e');
      }
      rethrow;
    }
  }

  static DateTime? getSessionExpiry() {
    try {
      final timestamp = _appBox?.get(_sessionExpiryKey);
      if (timestamp != null && timestamp is int) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error getting session expiry: $e');
      }
      return null;
    }
  }

  // Session validation
  static bool isSessionValid() {
    try {
      final expiry = getSessionExpiry();
      if (expiry == null) return false;
      return DateTime.now().isBefore(expiry);
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error checking session validity: $e');
      }
      return false;
    }
  }

  // Generic Methods
  static Future<void> setString(String key, String value) async {
    try {
      await _appBox?.put(key, value);
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error setting string $key: $e');
      }
      rethrow;
    }
  }

  static String? getString(String key) {
    try {
      return _appBox?.get(key);
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error getting string $key: $e');
      }
      return null;
    }
  }

  static Future<void> setBool(String key, bool value) async {
    try {
      await _appBox?.put(key, value);
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error setting bool $key: $e');
      }
      rethrow;
    }
  }

  static bool getBool(String key, {bool defaultValue = false}) {
    try {
      return _appBox?.get(key, defaultValue: defaultValue) ?? defaultValue;
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error getting bool $key: $e');
      }
      return defaultValue;
    }
  }

  static Future<void> setInt(String key, int value) async {
    try {
      await _appBox?.put(key, value);
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error setting int $key: $e');
      }
      rethrow;
    }
  }

  static int getInt(String key, {int defaultValue = 0}) {
    try {
      return _appBox?.get(key, defaultValue: defaultValue) ?? defaultValue;
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error getting int $key: $e');
      }
      return defaultValue;
    }
  }

  static Future<void> remove(String key) async {
    try {
      await _appBox?.delete(key);
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error removing $key: $e');
      }
    }
  }

  // Clear all stored data
  static Future<void> clearAll() async {
    try {
      await Future.wait([
        clearAuthToken(),
        clearRefreshToken(),
        clearAppPin(),
        clearUserData(),
        clearPhoneNumber(),
        clearLoginStatus(),
        clearPinSetupStatus(),
        clearResetToken(),
      ]);

      if (kDebugMode) {
        print('HiveStorageService: All data cleared successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error clearing all data: $e');
      }
      rethrow;
    }
  }

  // Tutorial and First Launch Methods
  static Future<void> setTutorialCompleted(bool completed) async {
    try {
      await _appBox?.put(_tutorialCompletedKey, completed);
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error setting tutorial completed: $e');
      }
      rethrow;
    }
  }

  static bool getTutorialCompleted() {
    try {
      return _appBox?.get(_tutorialCompletedKey, defaultValue: false) ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error getting tutorial completed: $e');
      }
      return false;
    }
  }

  static Future<void> setFirstAppLaunch(bool isFirst) async {
    try {
      await _appBox?.put(_firstAppLaunchKey, isFirst);
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error setting first app launch: $e');
      }
      rethrow;
    }
  }

  static bool isFirstAppLaunch() {
    try {
      return _appBox?.get(_firstAppLaunchKey, defaultValue: true) ?? true;
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error getting first app launch: $e');
      }
      return true;
    }
  }

  // Close all boxes (call this when app is closing)
  static Future<void> close() async {
    try {
      await Future.wait([
        _authBox?.close() ?? Future.value(),
        _userBox?.close() ?? Future.value(),
        _appBox?.close() ?? Future.value(),
      ]);

      if (kDebugMode) {
        print('HiveStorageService: All boxes closed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('HiveStorageService: Error closing boxes: $e');
      }
    }
  }

  // Get box info for debugging
  static Map<String, dynamic> getBoxInfo() {
    return {
      'authBox': {
        'isOpen': _authBox?.isOpen ?? false,
        'length': _authBox?.length ?? 0,
        'keys': _authBox?.keys.toList() ?? [],
      },
      'userBox': {
        'isOpen': _userBox?.isOpen ?? false,
        'length': _userBox?.length ?? 0,
        'keys': _userBox?.keys.toList() ?? [],
      },
      'appBox': {
        'isOpen': _appBox?.isOpen ?? false,
        'length': _appBox?.length ?? 0,
        'keys': _appBox?.keys.toList() ?? [],
      },
    };
  }
}
