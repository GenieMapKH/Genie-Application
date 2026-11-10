abstract class AppException implements Exception {
  final String message;
  final String? code;

  /// What was thrown underneath (a `DioException`), so a screen can still
  /// tell no internet from a slow connection.
  final Object? cause;

  const AppException(this.message, {this.code, this.cause});

  @override
  String toString() =>
      'AppException: $message ${code != null ? '($code)' : ''}';
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.cause});
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.cause});
}

class ServerException extends AppException {
  const ServerException(super.message, {super.code, super.cause});
}

class UnknownException extends AppException {
  const UnknownException(super.message, {super.code, super.cause});
}
