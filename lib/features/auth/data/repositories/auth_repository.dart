import 'dart:math';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tilomnov/core/errors/app_exceptions.dart';
import 'package:tilomnov/core/network/api_client.dart';
import 'package:tilomnov/core/network/api_cache_manager.dart';
import 'package:tilomnov/core/network/api_version_interceptor.dart';

/// Goes up by one each time the server ends this device's session: it was
/// signed out from another device, the password changed, or the account was
/// deactivated or deleted. The app shell listens and returns to the welcome
/// screen (`lib/app/app.dart`).
final sessionEndedProvider = StateProvider<int>((ref) => 0);

/// Whether someone is signed in on this device, from sign-in until sign-out
/// or the server ending the session. What is kept for the signed-in user
/// (profile, listings, favourites) watches it, so a guest never sees the
/// previous user's data or the actions only they may take.
final isSignedInProvider = NotifierProvider<SignedInNotifier, bool>(
  SignedInNotifier.new,
);

/// Follows the stored tokens ([AuthStorage.signedIn]).
class SignedInNotifier extends Notifier<bool> {
  @override
  bool build() {
    final signedIn = AuthStorage.signedIn;
    void follow() => state = signedIn.value;
    signedIn.addListener(follow);
    ref.onDispose(() => signedIn.removeListener(follow));
    return signedIn.value;
  }
}

final apiClientProvider = Provider<Dio>((ref) {
  return createApiClient(
    onSessionEnded: () => ref.read(sessionEndedProvider.notifier).state++,
    onApiVersionRetired: () =>
        ref.read(apiVersionRetiredProvider.notifier).state = true,
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
        return AuthException(
          message,
          code: e.response?.statusCode.toString(),
          cause: e,
        );
      }
      return NetworkException(
        message,
        code: e.response?.statusCode.toString(),
        cause: e,
      );
    }
    return UnknownException(e.toString(), cause: e);
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

  // 1. Standard Registration. The phone number is required; [email] and
  // [name] are optional (null leaves them out).
  Future<void> register({
    required String phone,
    String? email,
    String? name,
    required String password,
  }) async {
    try {
      await dio.post(
        '/auth/register',
        data: {
          'phone': phone,
          'email': ?email,
          'name': ?name,
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
        // Signed out on this phone anyway; the server ends the session
        // when its refresh token expires.
        AppLogger.error('Ending the session on the server failed', e);
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
