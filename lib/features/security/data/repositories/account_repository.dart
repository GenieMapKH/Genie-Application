import 'package:dio/dio.dart';

import 'package:genie/core/errors/app_exceptions.dart';

/// How the user shows they own the account before a change that cannot be
/// undone: their password, or a Google sign-in made a moment ago.
class IdentityProof {
  final String? _password;
  final String? _googleIdToken;

  const IdentityProof.password(String password)
    : _password = password,
      _googleIdToken = null;

  const IdentityProof.google(String idToken)
    : _password = null,
      _googleIdToken = idToken;

  Map<String, String> toJson() => {
    'password': ?_password,
    'idToken': ?_googleIdToken,
  };
}

/// The server did not accept the password or the Google confirmation.
class IdentityRejectedException extends AppException {
  const IdentityRejectedException()
    : super('Identity not confirmed', code: '403');
}

/// Too many wrong passwords in a row; the server refuses more for a while.
class TooManyAttemptsException extends AppException {
  const TooManyAttemptsException() : super('Too many attempts', code: '429');
}

/// API access for the account's password, and for deactivating or deleting
/// the account. Every call throws [IdentityRejectedException] for a wrong
/// proof and [TooManyAttemptsException] once the server stops accepting tries.
class AccountRepository {
  final Dio dio;

  AccountRepository(this.dio);

  /// Every other device is signed out; this one stays signed in.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _post('/auth/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  /// Gives an account that signs in with Google its first password.
  /// [googleIdToken] comes from signing in with Google again just now.
  Future<void> createPassword({
    required String googleIdToken,
    required String newPassword,
  }) async {
    await _post('/auth/account/password', {
      'idToken': googleIdToken,
      'newPassword': newPassword,
    });
  }

  /// A token, good for a few minutes, that proves the account password was
  /// just typed. The chat server accepts it in place of a forgotten backup
  /// PIN. [proof] must be a password: Google does not count here.
  Future<String> requestPasswordProof(IdentityProof proof) async {
    final response = await _post(
      '/auth/account/password-proof',
      proof.toJson(),
    );
    return response.data['proofToken'] as String;
  }

  /// Hides the account until the next sign-in, and signs every device out.
  Future<void> deactivate(IdentityProof proof) async {
    await _post('/auth/account/deactivate', proof.toJson());
  }

  /// Deletes the account and everything in it, for good.
  Future<void> delete(IdentityProof proof) async {
    await _post('/auth/account/delete', proof.toJson());
  }

  Future<Response<dynamic>> _post(String path, Map<String, String> body) async {
    try {
      return await dio.post(path, data: body);
    } on DioException catch (e) {
      throw switch (e.response?.statusCode) {
        403 => const IdentityRejectedException(),
        429 => const TooManyAttemptsException(),
        _ => e,
      };
    }
  }
}
