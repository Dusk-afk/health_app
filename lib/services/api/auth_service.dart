import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../config/env_config.dart';
import 'api_client.dart';

/// Service for handling authentication with the API
class AuthService {
  late final ApiClient _apiClient;
  final FlutterSecureStorage _secureStorage;

  // Keys for secure storage
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';

  // Token refresh configuration from env config
  static final int _tokenRefreshThreshold = EnvConfig.tokenRefreshThreshold;

  // Singleton instance
  static AuthService? _instance;

  // Stream controller for authentication state changes
  final _authStateController = StreamController<bool>.broadcast();

  /// Get the singleton instance of AuthService
  static AuthService get instance {
    _instance ??= AuthService._internal();
    return _instance!;
  }

  /// Private constructor
  AuthService._internal() : _secureStorage = const FlutterSecureStorage() {
    // Create API client without auth requirements for login/signup endpoints
    _apiClient = ApiClient(baseUrl: EnvConfig.apiUrl);
  }

  /// Stream of authentication state (true if authenticated, false if not)
  Stream<bool> get authStateChanges => _authStateController.stream;

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final accessToken = await _secureStorage.read(key: _accessTokenKey);
    if (accessToken == null) return false;

    try {
      final bool isExpired = JwtDecoder.isExpired(accessToken);

      // If token is expired, try to refresh it
      if (isExpired) {
        return await refreshToken();
      }

      // Check if token needs refresh (less than threshold time remaining)
      final Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);
      final int expiryTimestamp = decodedToken['exp'];
      final int currentTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final int timeRemaining = expiryTimestamp - currentTimestamp;

      if (timeRemaining < _tokenRefreshThreshold) {
        // Try to refresh the token in the background
        refreshToken();
      }

      return true;
    } catch (e) {
      // If there's any error decoding the token, assume it's invalid
      return false;
    }
  }

  /// Log in with phone number and password
  Future<Map<String, dynamic>> login(String phoneNumber, String password) async {
    try {
      final response = await _apiClient.post(
        EnvConfig.loginEndpoint,
        data: {
          'phone_number': phoneNumber,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        await _handleAuthResponse(response.data);
        _authStateController.add(true);
        return {'success': true, 'message': response.data['message'] ?? 'Login successful'};
      }

      return {'success': false, 'message': 'Login failed. Please check your credentials.'};
    } catch (e) {
      // The ApiClient already handles DioException and converts it to a proper error message
      return {'success': false, 'message': e.toString().replaceAll('Exception: ', '')};
    }
  }

  /// Sign up with name, phone number, and password
  Future<Map<String, dynamic>> signup({
    required String fullName,
    required String phoneNumber,
    required String password,
    String? email,
    String? username,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'full_name': fullName,
        'phone_number': phoneNumber,
        'password': password,
      };

      if (email != null) requestData['email'] = email;
      if (username != null) requestData['username'] = username;

      final response = await _apiClient.post(
        EnvConfig.signupEndpoint,
        data: requestData,
      );

      if (response.statusCode == 201) {
        await _handleAuthResponse(response.data);
        _authStateController.add(true);
        return {'success': true, 'message': response.data['message'] ?? 'Account created successfully'};
      }

      return {'success': false, 'message': 'Failed to create account'};
    } catch (e) {
      // The ApiClient already handles DioException and converts it to a proper error message
      return {'success': false, 'message': e.toString().replaceAll('Exception: ', '')};
    }
  }

  /// Log out the current user
  Future<void> logout() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _userDataKey);
    _authStateController.add(false);
  }

  /// Get the current user data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      // First check if we have user data in secure storage
      final cachedUserData = await _secureStorage.read(key: _userDataKey);

      if (cachedUserData != null) {
        return json.decode(cachedUserData) as Map<String, dynamic>;
      }

      // If not, fetch from API if authenticated
      if (await isAuthenticated()) {
        final token = await getAccessToken();

        final response =
            await _apiClient.get(EnvConfig.userProfileEndpoint, options: Options(headers: {'Authorization': 'Bearer $token'}));

        if (response.statusCode == 200 && response.data['user'] != null) {
          final userData = response.data['user'];
          await _secureStorage.write(
            key: _userDataKey,
            value: json.encode(userData),
          );
          return userData;
        }
      }

      return null;
    } catch (e) {
      // Just return null if there's an error, but could log the error here
      return null;
    }
  }

  /// Refresh the access token using the refresh token
  Future<bool> refreshToken() async {
    final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
    if (refreshToken == null) return false;

    try {
      final response = await _apiClient.post(
        EnvConfig.refreshTokenEndpoint,
        options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
      );

      if (response.statusCode == 200) {
        await _handleAuthResponse(response.data);
        return true;
      }
      return false;
    } catch (e) {
      // If refresh token is invalid, clear all tokens and logout
      await logout();
      return false;
    }
  }

  /// Get the access token for API requests
  Future<String?> getAccessToken() async {
    if (!await isAuthenticated()) {
      return null;
    }

    return await _secureStorage.read(key: _accessTokenKey);
  }

  /// Handle authentication response from login or token refresh
  Future<void> _handleAuthResponse(Map<String, dynamic> data) async {
    final accessToken = data['access_token'];
    final refreshToken = data['refresh_token'];
    final userData = data['user'];

    if (accessToken != null) {
      await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    }

    if (refreshToken != null) {
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    }

    if (userData != null) {
      await _secureStorage.write(
        key: _userDataKey,
        value: json.encode(userData),
      );
    }
  }
}
