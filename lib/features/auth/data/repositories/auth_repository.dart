import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:genie/core/errors/app_exceptions.dart';
import 'package:genie/core/network/api_client.dart';

final apiClientProvider = Provider<Dio>((ref) {
  return createApiClient();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(apiClientProvider));
});

class AuthService {
  final Dio dio;

  AuthService(this.dio);

  Exception _handleError(dynamic e) {
    if (e is DioException) {
      String message = e.message ?? 'An unknown network error occurred';
      if (e.response?.data is Map) {
        var msg = e.response?.data['message'];
        if (msg != null) {
          message = (msg is List) ? msg.join(', ') : msg.toString();
        }
      }
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        return AuthException(message, code: e.response?.statusCode.toString());
      }
      return NetworkException(message, code: e.response?.statusCode.toString());
    }
    return UnknownException(e.toString());
  }

  bool _isEmail(String value) {
    return RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(value.trim());
  }

  // 1. Standard Registration
  Future<void> register(String identifier, String password) async {
    final isEmail = _isEmail(identifier);
    try {
      await dio.post(
        '/auth/register',
        data: {
          isEmail ? 'email' : 'phone': identifier,
          'password': password,
        },
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 2. Standard Login
  Future<void> login(String identifier, String password) async {
    final isEmail = _isEmail(identifier);
    try {
      final response = await dio.post(
        '/auth/login',
        data: {
          isEmail ? 'email' : 'phone': identifier,
          'password': password,
        },
      );

      await AuthStorage.saveTokens(
        access: response.data['accessToken'],
        refresh: response.data['refreshToken'],
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 3. The Firebase Handshake (Google / Phone OTP)
  Future<void> firebaseLogin(User firebaseUser) async {
    try {
      final idToken = await firebaseUser.getIdToken();

      final response = await dio.post(
        '/auth/firebase-login',
        data: {'idToken': idToken},
      );

      await AuthStorage.saveTokens(
        access: response.data['accessToken'],
        refresh: response.data['refreshToken'],
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 4. Logout
  Future<void> logout() async {
    final refreshToken = await AuthStorage.getRefreshToken();
    if (refreshToken != null) {
      try {
        await dio.post('/auth/logout', data: {'refreshToken': refreshToken});
      } catch (e) {
        // Ignore errors, force local logout
      }
    }
    await AuthStorage.clearTokens();
  }
}

