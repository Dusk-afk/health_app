import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../config/env_config.dart';
import 'api_client.dart';


class AuthService {
  late final ApiClient _apiClient;
  final FlutterSecureStorage _secureStorage;


  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
static final int _tokenRefreshThreshold = EnvConfig.tokenRefreshThreshold;
static AuthService? _instance;

  final _authStateController = StreamController<bool>.broadcast();


  /// get single insta nce of authservice 
  static AuthService get instance {
    _instance ??= AuthService._internal();
    /// return _intance ;
    return _instance!;
  }
  AuthService._internal() : _secureStorage = const FlutterSecureStorage() {
    //api client created here !!!
    _apiClient = ApiClient(baseUrl: EnvConfig.apiUrl);
  }

  /// toggl e is done here 
  Stream<bool> get authStateChanges => _authStateController.stream;

  Future<bool> isAuthenticated() async {
    final accessToken = await _secureStorage.read(key: _accessTokenKey);
    if (accessToken == null) return false;

    try {
      final bool isExpired = JwtDecoder.isExpired(accessToken);


      if (isExpired) {
        //if the token gets expired or something... then refresh the token 
        return await refreshToken();
      }
      // threshold time 
      final Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);
      final int expiryTimestamp = decodedToken['exp'];
      final int currentTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final int timeRemaining = expiryTimestamp - currentTimestamp;

      if (timeRemaining < _tokenRefreshThreshold) {
        refreshToken();
      }

      return true;
    } catch (e) {
      // for error detection 
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

      return {'success': false, 'message': e.toString().replaceAll('Exception: ', '')};
    }
  }

  /// sign in happen there 
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
      // handling exceptinon with
      return {'success': false, 'message': e.toString().replaceAll('Exception: ', '')};
    }
  }

  /// loggg out 
  Future<void> logout() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _userDataKey);
    _authStateController.add(false);
  }

  /// fetch curr user data 
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      // secure storage mein hai data??

      final cachedUserData = await _secureStorage.read(key: _userDataKey);

      if (cachedUserData != null) {
        return json.decode(cachedUserData) as Map<String, dynamic>;
      }

      // fetch tabhi when it is authenticated 
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
      return null;
    }
  }

  /// refresh karne ka function using refresh token  (token ko refresh)
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
      // agar token is invlaid remove all the tokens 
      await logout();
      return false;
    }
  }

  //getting access token for api
  Future<String?> getAccessToken() async {
    if (!await isAuthenticated()) {
      return null;
    }

    return await _secureStorage.read(key: _accessTokenKey);
  }

  /// Handle auth response 
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
