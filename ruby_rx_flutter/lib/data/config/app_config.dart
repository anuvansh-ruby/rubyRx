import 'package:flutter/foundation.dart';

class AppConfig {
  static const bool isDebug = kDebugMode;

  // API Base URLs
  static const String _debugBaseUrl = 'http://192.168.1.222:5500/api';
  static const String _releaseBaseUrl =
      'https://your-production-domain.com/api';

  static String get baseUrl => isDebug ? _debugBaseUrl : _releaseBaseUrl;
  static String get debugBaseUrl => _debugBaseUrl;
  static String get releaseBaseUrl => _releaseBaseUrl;

  // Timeouts
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  static const int sendTimeout = 30000; // 30 seconds

  // Retry configuration
  static const int maxRetries = 3;
  static const int retryDelay = 1000; // 1 second

  // Storage keys
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String phoneNumberKey = 'phone_number';
  static const String isLoggedInKey = 'is_logged_in';

  // App Information
  static const String appName = 'Ruby AI';
  static const String appVersion = '1.0.0';

  // Debug flags
  static const bool enableApiLogging = true;
  static const bool enableErrorLogging = true;
}
