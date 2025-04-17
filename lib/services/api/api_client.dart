import 'package:dio/dio.dart';
import '../../config/env_config.dart';
import 'auth_service.dart';


class ApiClient {
  final Dio _dio;
  final String baseUrl;
  final bool requiresAuth;


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


    if (headers != null) {
      _dio.options.headers.addAll(headers);
    }


    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));


    if (requiresAuth) {
      _dio.interceptors.add(_createAuthInterceptor());
    }
  }


  Interceptor _createAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {

        final token = await AuthService.instance.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {

        if (error.response?.statusCode == 401) {

          final bool refreshed = await AuthService.instance.refreshToken();
          if (refreshed) {

            final token = await AuthService.instance.getAccessToken();
            if (token != null) {
              error.requestOptions.headers['Authorization'] = 'Bearer $token';


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

        return handler.next(error);
      },
    );
  }

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
