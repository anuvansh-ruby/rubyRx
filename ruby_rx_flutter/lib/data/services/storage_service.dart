import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const String _authTokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _phoneNumberKey = 'phone_number';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _pinSetupKey = 'pin_setup_status';
  static const String _resetTokenKey = 'reset_token';

  // Secure storage instance
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Shared preferences instance
  static SharedPreferences? _prefs;

  // Initialize shared preferences
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Auth Token Methods (using secure storage)
  static Future<void> setAuthToken(String token) async {
    await _secureStorage.write(key: _authTokenKey, value: token);
  }

  static Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: _authTokenKey);
  }

  static Future<void> clearAuthToken() async {
    await _secureStorage.delete(key: _authTokenKey);
  }

  // User Data Methods (using shared preferences for non-sensitive data)
  static Future<void> setUserData(Map<String, dynamic> userData) async {
    await _ensureInit();
    final userDataString = jsonEncode(userData);
    await _prefs!.setString(_userDataKey, userDataString);
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    await _ensureInit();
    final userDataString = _prefs!.getString(_userDataKey);
    if (userDataString != null) {
      try {
        return jsonDecode(userDataString) as Map<String, dynamic>;
      } catch (e) {
        // If decoding fails, return null and clear the corrupted data
        await clearUserData();
        return null;
      }
    }
    return null;
  }

  static Future<void> clearUserData() async {
    await _ensureInit();
    await _prefs!.remove(_userDataKey);
  }

  // Phone Number Methods
  static Future<void> setPhoneNumber(String phoneNumber) async {
    await _ensureInit();
    await _prefs!.setString(_phoneNumberKey, phoneNumber);
  }

  static Future<String?> getPhoneNumber() async {
    await _ensureInit();
    return _prefs!.getString(_phoneNumberKey);
  }

  static Future<void> clearPhoneNumber() async {
    await _ensureInit();
    await _prefs!.remove(_phoneNumberKey);
  }

  // Login Status Methods
  static Future<void> setLoginStatus(bool isLoggedIn) async {
    await _ensureInit();
    await _prefs!.setBool(_isLoggedInKey, isLoggedIn);
  }

  static Future<bool> getLoginStatus() async {
    await _ensureInit();
    return _prefs!.getBool(_isLoggedInKey) ?? false;
  }

  static Future<void> clearLoginStatus() async {
    await _ensureInit();
    await _prefs!.remove(_isLoggedInKey);
  }

  // Clear all stored data
  static Future<void> clearAll() async {
    await clearAuthToken();
    await clearUserData();
    await clearPhoneNumber();
    await clearLoginStatus();
  }

  // PIN Setup Status Methods
  static Future<void> setPinSetupStatus(bool isSetup) async {
    await _ensureInit();
    await _prefs!.setBool(_pinSetupKey, isSetup);
  }

  static Future<bool> getPinSetupStatus() async {
    await _ensureInit();
    return _prefs!.getBool(_pinSetupKey) ?? false;
  }

  static Future<void> clearPinSetupStatus() async {
    await _ensureInit();
    await _prefs!.remove(_pinSetupKey);
  }

  // Reset Token Methods (using secure storage)
  static Future<void> setResetToken(String token) async {
    await _secureStorage.write(key: _resetTokenKey, value: token);
  }

  static Future<String?> getResetToken() async {
    return await _secureStorage.read(key: _resetTokenKey);
  }

  static Future<void> clearResetToken() async {
    await _secureStorage.delete(key: _resetTokenKey);
  }

  // Generic Methods for any string data
  static Future<void> setString(String key, String value) async {
    await _ensureInit();
    await _prefs!.setString(key, value);
  }

  static Future<String?> getString(String key) async {
    await _ensureInit();
    return _prefs!.getString(key);
  }

  static Future<void> setBool(String key, bool value) async {
    await _ensureInit();
    await _prefs!.setBool(key, value);
  }

  static Future<bool> getBool(String key, {bool defaultValue = false}) async {
    await _ensureInit();
    return _prefs!.getBool(key) ?? defaultValue;
  }

  static Future<void> setInt(String key, int value) async {
    await _ensureInit();
    await _prefs!.setInt(key, value);
  }

  static Future<int> getInt(String key, {int defaultValue = 0}) async {
    await _ensureInit();
    return _prefs!.getInt(key) ?? defaultValue;
  }

  static Future<void> remove(String key) async {
    await _ensureInit();
    await _prefs!.remove(key);
  }

  // Private helper method
  static Future<void> _ensureInit() async {
    _prefs ??= await SharedPreferences.getInstance();
  }
}
