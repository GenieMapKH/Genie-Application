import 'package:dio/dio.dart';

import 'package:tilomnov/core/errors/app_exceptions.dart';
import 'package:tilomnov/core/storage/kept_copy_store.dart';
import 'package:tilomnov/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tilomnov/features/profile/data/models/user_profile.dart';

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

/// What the server says about a username that is being typed.
enum UsernameAvailability { available, taken, invalid }

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

  /// The profile as last read, kept for the signed-in account by default
  /// ([keptProfile]).
  final KeptCopyStore _kept;
  static const _keptName = 'profile.v1';

  UserRepository(this.dio, {Future<String?> Function()? accountId})
    : _kept = KeptCopyStore(account: accountId ?? AuthStorage.signedInUserId);

  /// Retries a few times: right after the first Google sign-in the new
  /// account can take a moment to become readable (404), and the gateway
  /// answers 502/504 while a service restarts. A lost connection is not
  /// retried here: the API client already repeats a passing drop, and an
  /// outage should show at once rather than after every repeat.
  Future<UserProfile> getProfile() async {
    var delay = const Duration(milliseconds: 1500);

    for (var attempt = 1; ; attempt++) {
      try {
        final response = await dio.get('/users/me');
        final data = response.data as Map<String, dynamic>;
        final profile = UserProfile.fromJson(data);
        await _kept.write(_keptName, data);
        return profile;
      } on DioException catch (e) {
        if (attempt == _maxAttempts || !_isWorthRetrying(e)) rethrow;
        await Future.delayed(delay);
        delay *= 1.5;
      }
    }
  }

  /// The profile as last read on this device, or null.
  Future<UserProfile?> keptProfile() =>
      _kept.read(_keptName, parse: UserProfile.fromJson);

  bool _isWorthRetrying(DioException e) =>
      const [404, 502, 504].contains(e.response?.statusCode);

  /// Asks whether [username] could be chosen: well formed, and not another
  /// account's. The user's own current username counts as available. Only an
  /// answer to show while typing: saving is what decides.
  Future<UsernameAvailability> checkUsername(String username) async {
    final response = await dio.get(
      '/users/username-available',
      queryParameters: {'username': username},
    );
    final answer = response.data as Map<String, dynamic>;
    if (answer['available'] == true) return UsernameAvailability.available;
    return answer['reason'] == 'invalid'
        ? UsernameAvailability.invalid
        : UsernameAvailability.taken;
  }

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
