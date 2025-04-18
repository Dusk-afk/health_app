/// Environment configuration for the application
class EnvConfig {
  /// Private constructor to prevent instantiation
  EnvConfig._();

  /// Base URL for API requests
  // static const String baseUrl = 'http://127.0.0.1:8000';
  static const String baseUrl = 'https://e957-2409-40d0-2004-114f-70ed-7751-a1fd-a864.ngrok-free.app';

  /// API version path
  static const String apiVersion = '/api/v1';

  /// Full API URL including version
  static String get apiUrl => '$baseUrl$apiVersion';

  /// Authentication endpoints
  static const String loginEndpoint = '/auth/login';
  static const String signupEndpoint = '/auth/signup';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String userProfileEndpoint = '/auth/me';

  /// Medical vault endpoints
  static const String documentsEndpoint = '/documents';

  /// Health data endpoints
  static const String healthDataEndpoint = '/health-data';

  /// Connection timeout in seconds
  static const int connectionTimeout = 30;

  /// Receive timeout in seconds
  static const int receiveTimeout = 30;

  /// Token refresh threshold in seconds (5 minutes)
  static const int tokenRefreshThreshold = 5 * 60;
}
