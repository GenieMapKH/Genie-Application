import 'package:dio/dio.dart';

import 'package:genie/core/errors/app_exceptions.dart';
import 'package:genie/features/profile/data/models/user_profile.dart';

/// A field of the profile the user can change, one at a time.
enum ProfileField {
  username('username'),

  /// The name other people see (the server calls it `name`).
  displayName('name'),
  firstName('firstName'),
  lastName('lastName'),
  sex('sex'),
  phone('phone');

  /// The key `PATCH /users/me` expects for this field.
  final String apiName;

  const ProfileField(this.apiName);
}

/// The server refused a value because another account already has it
/// (a username or a phone number).
class ProfileValueTakenException extends AppException {
  const ProfileValueTakenException() : super('Already taken', code: '409');
}

/// The server refused a value as badly formed.
class ProfileValueInvalidException extends AppException {
  const ProfileValueInvalidException() : super('Invalid value', code: '400');
}

/// API access for the signed-in user's own profile.
class UserRepository {
  static const _maxAttempts = 4;

  final Dio dio;

  UserRepository(this.dio);

  /// Retries a few times: right after the first Google sign-in the new
  /// account can take a moment to become readable (404), and the gateway
  /// answers 502/504 while a service restarts.
  Future<UserProfile> getProfile() async {
    var delay = const Duration(milliseconds: 1500);

    for (var attempt = 1; ; attempt++) {
      try {
        final response = await dio.get('/users/me');
        return UserProfile.fromJson(response.data as Map<String, dynamic>);
      } on DioException catch (e) {
        if (attempt == _maxAttempts || !_isWorthRetrying(e)) rethrow;
        await Future.delayed(delay);
        delay *= 1.5;
      }
    }
  }

  bool _isWorthRetrying(DioException e) =>
      e.type == DioExceptionType.connectionError ||
      const [404, 502, 504].contains(e.response?.statusCode);

  /// Changes one field; null clears it. Throws [ProfileValueTakenException]
  /// or [ProfileValueInvalidException] when the server refuses the value.
  Future<UserProfile> updateField(ProfileField field, String? value) async {
    try {
      final response = await dio.patch(
        '/users/me',
        data: {field.apiName: value},
      );
      return UserProfile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw switch (e.response?.statusCode) {
        409 => const ProfileValueTakenException(),
        400 => const ProfileValueInvalidException(),
        _ => e,
      };
    }
  }
}
