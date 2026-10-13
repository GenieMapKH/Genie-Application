import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/profile/data/repositories/user_repository.dart';

/// How saving one profile field ended. The screen turns this into a message.
enum ProfileSaveResult {
  saved,

  /// The value is not allowed for this field (shape or length).
  invalid,

  /// Another account already has this username or phone number.
  taken,

  /// The server could not be reached or failed.
  failed,
}

/// What is known about a username while the user types it.
enum UsernameCheck {
  available,

  /// Another account has it.
  taken,

  /// Not a username at all (length or characters).
  invalid,

  /// The server could not be asked. The user may still try: saving decides.
  unknown,
}

/// The rules for each editable profile field, and saving one. No UI.
class ProfileEditController {
  /// Same rule as the server: 3 to 30 lowercase letters, digits, "_" or ".".
  static final _username = RegExp(r'^[a-z0-9_.]{3,30}$');

  static const _maxLengths = {
    ProfileField.displayName: 60,
    ProfileField.firstName: 50,
    ProfileField.lastName: 50,
    ProfileField.phone: 20,
  };

  final UserRepository _repository;

  /// Called after a successful save, so the profile is loaded again.
  final void Function() _onSaved;

  ProfileEditController(this._repository, {required void Function() onSaved})
    : _onSaved = onSaved;

  /// What [input] is saved as: trimmed, usernames in lowercase, and null
  /// for an empty field (which clears it).
  static String? normalize(ProfileField field, String? input) {
    final trimmed = input?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return field == ProfileField.username ? trimmed.toLowerCase() : trimmed;
  }

  /// Whether [value] (already normalized) may be saved for [field].
  static bool isValid(ProfileField field, String? value) {
    if (field == ProfileField.username) {
      return value != null && _username.hasMatch(value);
    }
    // A phone number may be the only way to sign in, so it cannot be emptied.
    if (field == ProfileField.phone && value == null) return false;
    final maxLength = _maxLengths[field];
    return value == null || maxLength == null || value.length <= maxLength;
  }

  /// Whether [input] could be this user's username. A badly formed one is
  /// answered here without asking the server.
  Future<UsernameCheck> checkUsername(String input) async {
    final value = normalize(ProfileField.username, input);
    if (value == null || !isValid(ProfileField.username, value)) {
      return UsernameCheck.invalid;
    }

    try {
      return switch (await _repository.checkUsername(value)) {
        UsernameAvailability.available => UsernameCheck.available,
        UsernameAvailability.taken => UsernameCheck.taken,
        UsernameAvailability.invalid => UsernameCheck.invalid,
      };
    } catch (e) {
      AppLogger.error('Could not check the username', e);
      return UsernameCheck.unknown;
    }
  }

  Future<ProfileSaveResult> save(ProfileField field, String? input) async {
    final value = normalize(field, input);
    if (!isValid(field, value)) return ProfileSaveResult.invalid;

    try {
      await _repository.updateField(field, value);
    } on ProfileValueTakenException {
      return ProfileSaveResult.taken;
    } on ProfileValueInvalidException {
      return ProfileSaveResult.invalid;
    } catch (e) {
      AppLogger.error('Could not save ${field.apiName}', e);
      return ProfileSaveResult.failed;
    }

    _onSaved();
    return ProfileSaveResult.saved;
  }
}
