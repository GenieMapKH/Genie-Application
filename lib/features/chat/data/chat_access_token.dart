import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/auth/data/datasources/auth_local_data_source.dart';

/// Supplies the access token for the chat socket handshake.
///
/// A session is only renewed by the API client, when a request comes back
/// 401. A socket never makes such a request, so when the stored token has
/// expired one cheap request is made first and the renewed token is used.
class ChatAccessToken {
  final Dio dio;

  ChatAccessToken({required this.dio});

  /// A token the server should accept, or null when signed out.
  ///
  /// [afterRejection] means the server just refused the stored token. Its
  /// clock decides, not this device's, so the session is checked even if
  /// the token does not look expired from here.
  Future<String?> read({bool afterRejection = false}) async {
    final token = await AuthStorage.getAccessToken();
    if (token == null) return null;
    if (!afterRejection && !_isExpired(token)) return token;

    try {
      await dio.get('/users/me');
    } on DioException catch (e) {
      AppLogger.error('Could not renew the session for chat', e);
    }
    return AuthStorage.getAccessToken();
  }

  /// Whether the JWT's `exp` has passed or is about to.
  bool _isExpired(String jwt) {
    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(jwt.split('.')[1]))),
      );
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(
        (payload['exp'] as num).toInt() * 1000,
      );
      return DateTime.now().isAfter(
        expiresAt.subtract(const Duration(seconds: 30)),
      );
    } catch (_) {
      // Not a readable JWT: let the server decide.
      return false;
    }
  }
}
