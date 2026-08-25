import 'package:dio/dio.dart';
import '../storage/auth_storage.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;
  bool _isRefreshing = false;

  AuthInterceptor(this.dio);

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

    _isRefreshing = true;
    final refreshToken = await AuthStorage.getRefreshToken();

    if (refreshToken == null) {
      _isRefreshing = false;
      return handler.next(err);
    }

    try {
      // 1. Call backend to rotate tokens
      final refreshResponse = await dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final newAccess = refreshResponse.data['accessToken'];
      final newRefresh = refreshResponse.data['refreshToken'];

      // 2. Save the new tokens
      await AuthStorage.saveTokens(access: newAccess, refresh: newRefresh);

      // 3. Retry the ORIGINAL request that failed
      final requestOptions = err.requestOptions;
      requestOptions.headers['Authorization'] = 'Bearer $newAccess';

      final retryResponse = await dio.fetch(requestOptions);
      _isRefreshing = false;
      return handler.resolve(retryResponse);
    } catch (e) {
      // Token theft detected or completely expired!
      _isRefreshing = false;
      await AuthStorage.clearTokens();
      // TODO: Use your navigator key to force the app to the LoginScreen
      return handler.next(err);
    }
  }
}
