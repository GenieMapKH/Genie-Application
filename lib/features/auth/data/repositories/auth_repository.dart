import 'dart:math';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:genie/core/logging/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:genie/core/errors/app_exceptions.dart';
import 'package:genie/core/network/api_client.dart';
import 'package:genie/core/network/api_cache_manager.dart';

/// Goes up by one each time the server ends this device's session: it was
/// signed out from another device, the password changed, or the account was
/// deactivated or deleted. The app shell listens and returns to the welcome
/// screen (`lib/app/app.dart`).
final sessionEndedProvider = StateProvider<int>((ref) => 0);

final apiClientProvider = Provider<Dio>((ref) {
  return createApiClient(
    onSessionEnded: () => ref.read(sessionEndedProvider.notifier).state++,
  );
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

  /// Gives this device an anonymous session so guests can browse.
  /// Never throws: browsing must keep working if registration fails.
  Future<void> ensureGuestSession() async {
    try {
      var guestId = await AuthStorage.getGuestSessionId();
      if (guestId == null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final random = Random.secure().nextInt(1000000);
        guestId = 'guest_${timestamp}_$random';
        await AuthStorage.saveGuestSessionId(guestId);
      }

      await dio.post(
        '/public/properties/guest-session',
        data: {'deviceId': guestId},
      );
    } catch (e) {
      AppLogger.error('Guest session init failed', e);
    }
  }

  // 1. Standard Registration
  Future<void> register(String identifier, String password) async {
    final isEmail = _isEmail(identifier);
    try {
      await dio.post(
        '/auth/register',
        data: {isEmail ? 'email' : 'phone': identifier, 'password': password},
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
        data: {isEmail ? 'email' : 'phone': identifier, 'password': password},
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
    ApiCacheManager().clearAll();
  }

  // 5. Forgot Password — Request OTP
  Future<void> forgotPassword(String email) async {
    try {
      await dio.post('/auth/forgot-password', data: {'email': email});
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 6. Verify OTP
  Future<bool> verifyOtp(String email, String otp) async {
    try {
      final response = await dio.post(
        '/auth/verify-otp',
        data: {'email': email, 'otp': otp},
      );
      return response.data['verified'] == true;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 7. Reset Password
  Future<void> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {
    try {
      await dio.post(
        '/auth/reset-password',
        data: {'email': email, 'otp': otp, 'newPassword': newPassword},
      );
    } catch (e) {
      throw _handleError(e);
    }
  }
}
