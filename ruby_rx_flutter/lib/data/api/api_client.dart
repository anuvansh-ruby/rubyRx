import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../services/hive_storage_service.dart';
import '../config/app_config.dart';

class ApiClient {
  late Dio _dio;
  static ApiClient? _instance;

  ApiClient._() {
    _dio = Dio();
    _initializeInterceptors();
  }

  static ApiClient get instance {
    _instance ??= ApiClient._();
    return _instance!;
  }

  Dio get dio => _dio;

  void _initializeInterceptors() {
    _dio.options = BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: Duration(milliseconds: AppConfig.connectTimeout),
      receiveTimeout: Duration(milliseconds: AppConfig.receiveTimeout),
      sendTimeout: Duration(milliseconds: AppConfig.sendTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': '${AppConfig.appName}/${AppConfig.appVersion}',
      },
    );

    // Add pretty logger for debugging (only in debug mode)
    if (AppConfig.isDebug && AppConfig.enableApiLogging) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 90,
        ),
      );
    }

    // Add auth token interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token to requests if available
          final token = HiveStorageService.getAuthToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = token;
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          // Handle all 2xx responses as success
          if (response.statusCode != null &&
              response.statusCode! >= 200 &&
              response.statusCode! < 300) {
            handler.next(response);
          } else {
            handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                type: DioExceptionType.badResponse,
                message:
                    'HTTP ${response.statusCode}: ${response.statusMessage}',
              ),
            );
          }
        },
        onError: (error, handler) async {
          // Handle different error scenarios
          await _handleApiError(error, handler);
        },
      ),
    );

    // Add retry interceptor for network errors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (_shouldRetry(error) &&
              error.requestOptions.extra['retryCount'] == null) {
            error.requestOptions.extra['retryCount'] = 0;
          }

          final retryCount = error.requestOptions.extra['retryCount'] ?? 0;

          if (_shouldRetry(error) && retryCount < AppConfig.maxRetries) {
            error.requestOptions.extra['retryCount'] = retryCount + 1;

            // Wait before retry
            await Future.delayed(
              Duration(
                milliseconds: (AppConfig.retryDelay * (retryCount + 1)).round(),
              ),
            );

            try {
              final response = await _dio.fetch(error.requestOptions);
              handler.resolve(response);
            } catch (e) {
              handler.next(error);
            }
          } else {
            handler.next(error);
          }
        },
      ),
    );
  }

  // Handle API errors with specific status codes
  Future<void> _handleApiError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    switch (error.response?.statusCode) {
      case 401:
        // Unauthorized - clear auth data and redirect to login
        await HiveStorageService.clearAuthToken();
        await HiveStorageService.setLoginStatus(false);
        // You can add navigation logic here if needed
        break;
      case 403:
        // Forbidden - user doesn't have permission
        break;
      case 404:
        // Not found
        break;
      case 408:
        // Request timeout
        break;
      case 409:
        // Conflict
        break;
      case 422:
        // Validation error
        break;
      case 429:
        // Rate limit exceeded
        break;
      case 500:
        // Internal server error
        break;
      case 502:
        // Bad gateway
        break;
      case 503:
        // Service unavailable
        break;
      case 504:
        // Gateway timeout
        break;
      default:
        break;
    }

    handler.next(error);
  }

  // Check if request should be retried
  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError ||
        (error.response?.statusCode != null &&
            (error.response!.statusCode! >= 500 ||
                error.response!.statusCode == 408 ||
                error.response!.statusCode == 429));
  } // Update base URL (useful for switching between dev/prod environments)

  void updateBaseUrl(String newBaseUrl) {
    _dio.options.baseUrl = newBaseUrl;
  }

  // Add custom headers
  void addHeader(String key, String value) {
    _dio.options.headers[key] = value;
  }

  // Remove header
  void removeHeader(String key) {
    _dio.options.headers.remove(key);
  }

  // Clear all headers
  void clearHeaders() {
    _dio.options.headers.clear();
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.headers['Accept'] = 'application/json';
  }
}
