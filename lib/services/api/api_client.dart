import 'package:dio/dio.dart';
import '../../config/env_config.dart';
import 'auth_service.dart';

/// Base API client that handles HTTP requests using Dio package
class ApiClient {
  final Dio _dio;
  final String baseUrl;
  final bool requiresAuth;

  /// Create an instance of ApiClient with the given baseUrl and optional Dio instance
  ApiClient({
    String? baseUrl,
    Dio? dio,
    Map<String, dynamic>? headers,
    this.requiresAuth = false,
  })  : baseUrl = baseUrl ?? EnvConfig.apiUrl,
        _dio = dio ?? Dio() {
    _dio.options.baseUrl = this.baseUrl;
    _dio.options.connectTimeout = Duration(seconds: EnvConfig.connectionTimeout);
    _dio.options.receiveTimeout = Duration(seconds: EnvConfig.receiveTimeout);
    _dio.options.responseType = ResponseType.json;

    // Set default headers if provided
    if (headers != null) {
      _dio.options.headers.addAll(headers);
    }

    // Add interceptors for logging
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));

    // Add authorization interceptor if required
    if (requiresAuth) {
      _dio.interceptors.add(_createAuthInterceptor());
    }
  }

  /// Create an interceptor for handling authentication tokens
  Interceptor _createAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Only add token for auth-required endpoints
        final token = await AuthService.instance.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // If we get a 401 error, try to refresh the token and retry the request
        if (error.response?.statusCode == 401) {
          // Try to refresh the token
          final bool refreshed = await AuthService.instance.refreshToken();
          if (refreshed) {
            // If token refresh was successful, retry the original request
            final token = await AuthService.instance.getAccessToken();
            if (token != null) {
              error.requestOptions.headers['Authorization'] = 'Bearer $token';

              // Create a new request with the updated token
              final options = Options(
                method: error.requestOptions.method,
                headers: error.requestOptions.headers,
              );

              final response = await _dio.request<dynamic>(
                error.requestOptions.path,
                data: error.requestOptions.data,
                queryParameters: error.requestOptions.queryParameters,
                options: options,
              );

              return handler.resolve(response);
            }
          }
        }
        // If token refresh failed or it wasn't a 401 error, forward the error
        return handler.next(error);
      },
    );
  }

  /// GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle Dio errors and convert them to more readable exceptions
  Exception _handleError(DioException error) {
    String errorMessage = 'An error occurred while connecting to the server';

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorMessage = 'Connection timeout. Please check your internet connection';
        break;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;

        if (responseData != null && responseData is Map<String, dynamic>) {
          errorMessage = responseData['error'] ?? 'Server error: $statusCode';
        } else {
          errorMessage = 'Server error: $statusCode';
        }
        break;
      case DioExceptionType.cancel:
        errorMessage = 'Request was cancelled';
        break;
      case DioExceptionType.unknown:
        if (error.error != null) {
          errorMessage = error.error.toString();
        }
        break;
      default:
        errorMessage = 'Network error occurred';
        break;
    }

    return Exception(errorMessage);
  }
}
