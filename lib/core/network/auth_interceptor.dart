import 'package:dio/dio.dart';
import 'package:tilomnov/features/auth/data/datasources/auth_local_data_source.dart';

/// Attaches the session to every request, and renews it when the server
/// answers that the access token is no longer good.
class AuthInterceptor extends Interceptor {
  /// Marks the renewal request itself, and requests already repeated with a
  /// renewed token: a 401 to either is final.
  static const _noRenewal = 'auth_no_renewal';

  final Dio dio;

  /// Called when the server will not renew this device's session: it was
  /// signed out from another device, the password changed, or the account
  /// was deactivated or deleted. The stored tokens are already gone.
  final void Function()? onSessionEnded;

  /// The renewal in progress. Requests refused while it runs (the app wakes
  /// up and sends several at once with the same expired token) wait for it
  /// instead of each failing or renewing again.
  Future<String?>? _renewal;

  AuthInterceptor(this.dio, {this.onSessionEnded});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    var token = await AuthStorage.getAccessToken();
    if (token != null &&
        options.extra[_noRenewal] != true &&
        AuthStorage.isTokenExpired(token)) {
      // Renewed before sending: a public read (the map, a listing) answers
      // an expired token as it answers a guest, without the owner's phone,
      // instead of refusing it, so the renewal on a 401 would never come.
      await _renew();
      token = await AuthStorage.getAccessToken();
    }
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
    final request = err.requestOptions;
    if (err.response?.statusCode != 401 || request.extra[_noRenewal] == true) {
      return handler.next(err);
    }

    final newAccess = await _validAccessToken(request);
    if (newAccess == null) {
      return handler.next(err);
    }

    // Repeat the ORIGINAL request that failed. Whatever happens to it now is
    // its own result, not a reason to doubt the session.
    try {
      request.headers['Authorization'] = 'Bearer $newAccess';
      request.extra[_noRenewal] = true;
      return handler.resolve(await dio.fetch(request));
    } on DioException catch (retryError) {
      return handler.next(retryError);
    }
  }

  /// A token to repeat [refused] with: the one another request renewed
  /// meanwhile, else a newly renewed one. Null when there is none.
  Future<String?> _validAccessToken(RequestOptions refused) async {
    final current = await AuthStorage.getAccessToken();
    if (current != null &&
        refused.headers['Authorization'] != 'Bearer $current') {
      return current;
    }
    return _renew();
  }

  /// The renewal in progress, else a new one. Null when there is no session
  /// to renew or it could not be renewed.
  Future<String?> _renew() async {
    final pending = _renewal;
    if (pending != null) return pending;

    final refreshToken = await AuthStorage.getRefreshToken();
    if (refreshToken == null) return null;

    // Checked again: another request may have started one while the
    // storage was read.
    return _renewal ??= _renewSession(
      refreshToken,
    ).whenComplete(() => _renewal = null);
  }

  /// Trades the refresh token for a new pair and returns the new access
  /// token. Null when that did not work: either the server refused, which
  /// ends the session, or it could not be reached, which changes nothing.
  Future<String?> _renewSession(String refreshToken) async {
    try {
      final response = await dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(extra: {_noRenewal: true}),
      );
      final newAccess = response.data['accessToken'] as String;
      // Signed out while the renewal ran: saving would sign the device back
      // in behind the user's back.
      if (await AuthStorage.getRefreshToken() != refreshToken) return null;
      await AuthStorage.saveTokens(
        access: newAccess,
        refresh: response.data['refreshToken'] as String,
      );
      return newAccess;
    } on DioException catch (e) {
      // Only a refusal ends the session. Being offline for a moment must
      // not sign anyone out, and a session the user already left (signing
      // out revokes the refresh token) is not ended a second time.
      if (e.response?.statusCode == 401 &&
          await AuthStorage.getRefreshToken() == refreshToken) {
        await AuthStorage.clearTokens();
        onSessionEnded?.call();
      }
      return null;
    }
  }
}
