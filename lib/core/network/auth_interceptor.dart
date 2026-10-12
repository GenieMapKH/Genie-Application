import 'package:dio/dio.dart';
import 'package:genie/features/auth/data/datasources/auth_local_data_source.dart';

/// Attaches the session to every request, and renews it when the server
/// answers that the access token is no longer good.
class AuthInterceptor extends Interceptor {
  final Dio dio;

  /// Called when the server will not renew this device's session: it was
  /// signed out from another device, the password changed, or the account
  /// was deactivated or deleted. The stored tokens are already gone.
  final void Function()? onSessionEnded;

  bool _isRefreshing = false;

  AuthInterceptor(this.dio, {this.onSessionEnded});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await AuthStorage.getAccessToken();
    if (token != null) {
      // Automatically attach token to ALL requests if user is logged in
      options.headers['Authorization'] = 'Bearer $token';
    } else {
      final guestId = await AuthStorage.getGuestSessionId();
      if (guestId != null) {
        options.headers['X-Guest-Session-ID'] = guestId;
      }
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // If error isn't 401, or we're already refreshing, pass it along
    if (err.response?.statusCode != 401 || _isRefreshing) {
      return handler.next(err);
    }

    final refreshToken = await AuthStorage.getRefreshToken();
    if (refreshToken == null) {
      return handler.next(err);
    }

    final newAccess = await _renewSession(refreshToken);
    if (newAccess == null) {
      return handler.next(err);
    }

    // Retry the ORIGINAL request that failed. Whatever happens to it now is
    // its own result, not a reason to doubt the session.
    try {
      final requestOptions = err.requestOptions;
      requestOptions.headers['Authorization'] = 'Bearer $newAccess';
      return handler.resolve(await dio.fetch(requestOptions));
    } on DioException catch (retryError) {
      return handler.next(retryError);
    }
  }

  /// Trades the refresh token for a new pair and returns the new access
  /// token. Null when that did not work: either the server refused, which
  /// ends the session, or it could not be reached, which changes nothing.
  Future<String?> _renewSession(String refreshToken) async {
    _isRefreshing = true;
    try {
      final response = await dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final newAccess = response.data['accessToken'] as String;
      await AuthStorage.saveTokens(
        access: newAccess,
        refresh: response.data['refreshToken'] as String,
      );
      return newAccess;
    } on DioException catch (e) {
      // Only a refusal ends the session. Being offline for a moment must
      // not sign anyone out.
      if (e.response?.statusCode == 401) {
        await AuthStorage.clearTokens();
        onSessionEnded?.call();
      }
      return null;
    } finally {
      _isRefreshing = false;
    }
  }
}
