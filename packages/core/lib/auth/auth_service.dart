import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'role.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String _tokenKey = 'auth_token';
  final String _userKey = 'user_data';
  final String _refreshTokenKey = 'refresh_token';

  String? _token;
  Map<String, dynamic>? _currentUser;
  Role? _userRole;

  // Stream for auth state changes
  final _authStateController = StreamController<AuthState>.broadcast();
  Stream<AuthState> get authStateStream => _authStateController.stream;

  AuthState get currentAuthState {
    if (_token == null) return AuthState.unauthenticated;
    if (JwtDecoder.isExpired(_token!)) return AuthState.expired;
    return AuthState.authenticated;
  }

  Future<bool> login(String email, String password) async {
    try {
      // TODO: Replace with actual API call
      // final response = await ApiClient().post('/api/auth/login', data: {
      //   'email': email,
      //   'password': password,
      // });

      // Simulated response for now
      final response = {
        'success': true,
        'data': {
          'token': 'simulated_jwt_token',
          'user': {
            'id': 'user_123',
            'email': email,
            'full_name': 'Test User',
            'role': 'admin',
          },
          'refresh_token': 'simulated_refresh_token',
        },
      };

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        _token = data['token'] as String;
        final userData = data['user'] as Map<String, dynamic>;
        _currentUser = userData;
        _userRole = _parseRole(userData['role'] as String);

        // Store securely
        await _secureStorage.write(key: _tokenKey, value: _token);
        await _secureStorage.write(
          key: _userKey,
          value: jsonEncode(userData),
        );
        if (data['refresh_token'] != null) {
          await _secureStorage.write(
            key: _refreshTokenKey,
            value: data['refresh_token'] as String,
          );
        }

        _authStateController.add(AuthState.authenticated);
        return true;
      }
      return false;
    } catch (e) {
      _authStateController.add(AuthState.error);
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    _userRole = null;
    await _secureStorage.deleteAll();
    _authStateController.add(AuthState.unauthenticated);
  }

  Future<bool> refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      if (refreshToken == null) return false;

      // TODO: Replace with actual API call
      // final response = await ApiClient().post('/api/auth/refresh', data: {
      //   'refresh_token': refreshToken,
      // });

      // Simulated response for now
      final response = {
        'success': true,
        'data': {
          'token': 'new_simulated_jwt_token',
          'refresh_token': 'new_simulated_refresh_token',
        },
      };

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        _token = data['token'] as String;
        await _secureStorage.write(key: _tokenKey, value: _token);
        if (data['refresh_token'] != null) {
          await _secureStorage.write(
            key: _refreshTokenKey,
            value: data['refresh_token'] as String,
          );
        }
        _authStateController.add(AuthState.authenticated);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkAndRefreshToken() async {
    if (_token == null) {
      await _loadStoredToken();
    }

    if (_token == null) return false;

    if (JwtDecoder.isExpired(_token!)) {
      return await refreshToken();
    }
    return true;
  }

  Future<void> _loadStoredToken() async {
    _token = await _secureStorage.read(key: _tokenKey);
    final userJson = await _secureStorage.read(key: _userKey);
    if (userJson != null && _token != null) {
      final userData = jsonDecode(userJson) as Map<String, dynamic>;
      _currentUser = userData;
      _userRole = _parseRole(userData['role'] as String);
    }
  }

  Role? _parseRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Role.admin;
      case 'carer':
        return Role.carer;
      case 'client':
        return Role.client;
      case 'warehouse':
        return Role.warehouse;
      case 'family':
        return Role.family;
      default:
        return null;
    }
  }

  String? get token => _token;
  Map<String, dynamic>? get currentUser => _currentUser;
  Role? get userRole => _userRole;
  bool get isAuthenticated => _token != null && !JwtDecoder.isExpired(_token!);
}

enum AuthState {
  unauthenticated,
  authenticated,
  expired,
  error,
  loading,
}