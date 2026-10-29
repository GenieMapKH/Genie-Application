import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/features/security/data/repositories/account_repository.dart';

/// How a change that needs proof of identity ended. The screen turns this
/// into a message.
enum AccountActionResult {
  done,

  /// The password or the Google confirmation was not accepted.
  identityRejected,
  tooManyAttempts,

  /// This device signed in less than a day ago and may not do this yet.
  deviceTooNew,

  /// Another account already uses the email.
  emailTaken,

  /// The server could not be reached or failed.
  failed,
}

/// Why a new password was refused before it was sent anywhere.
enum PasswordProblem { currentMissing, tooShort, mismatch, sameAsCurrent }

/// The account's password and email, and deactivating or deleting the
/// account. No UI.
class AccountSecurityController {
  /// Same rule as the server.
  static const minPasswordLength = 8;

  final AccountRepository _repository;

  AccountSecurityController(this._repository);

  /// The first thing wrong with what the user typed, or null when it can be
  /// sent to the server.
  static PasswordProblem? checkNewPassword({
    required String current,
    required String next,
    required String confirmation,
  }) {
    if (current.isEmpty) return PasswordProblem.currentMissing;
    final problem = checkFirstPassword(next: next, confirmation: confirmation);
    if (problem != null) return problem;
    if (next == current) return PasswordProblem.sameAsCurrent;
    return null;
  }

  /// As [checkNewPassword], for an account that has no password yet.
  static PasswordProblem? checkFirstPassword({
    required String next,
    required String confirmation,
  }) {
    if (next.length < minPasswordLength) return PasswordProblem.tooShort;
    if (next != confirmation) return PasswordProblem.mismatch;
    return null;
  }

  Future<AccountActionResult> changePassword({
    required String current,
    required String next,
  }) {
    return _attempt(
      'change password',
      () => _repository.changePassword(
        currentPassword: current,
        newPassword: next,
      ),
    );
  }

  /// The first password of an account that signs in with Google, confirmed
  /// by signing in with Google again ([googleIdToken]).
  Future<AccountActionResult> createPassword({
    required String googleIdToken,
    required String password,
  }) {
    return _attempt(
      'create password',
      () => _repository.createPassword(
        googleIdToken: googleIdToken,
        newPassword: password,
      ),
    );
  }

  /// Adds [email] to an account that has none, confirmed with [password].
  Future<AccountActionResult> addEmail({
    required String email,
    required String password,
  }) {
    return _attempt(
      'add email',
      () => _repository.addEmail(
        email: email.trim().toLowerCase(),
        password: password,
      ),
    );
  }

  /// Asks the server to confirm the account password in [proof]. With
  /// [AccountActionResult.done] comes the token that stands in for a
  /// forgotten chat backup PIN.
  Future<({AccountActionResult result, String? proofToken})> provePassword(
    IdentityProof proof,
  ) async {
    String? proofToken;
    final result = await _attempt('confirm password', () async {
      proofToken = await _repository.requestPasswordProof(proof);
    });
    return (result: result, proofToken: proofToken);
  }

  Future<AccountActionResult> deactivate(IdentityProof proof) =>
      _attempt('deactivate account', () => _repository.deactivate(proof));

  Future<AccountActionResult> delete(IdentityProof proof) =>
      _attempt('delete account', () => _repository.delete(proof));

  Future<AccountActionResult> _attempt(
    String what,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      return AccountActionResult.done;
    } on IdentityRejectedException {
      return AccountActionResult.identityRejected;
    } on TooManyAttemptsException {
      return AccountActionResult.tooManyAttempts;
    } on DeviceTooNewException {
      return AccountActionResult.deviceTooNew;
    } on EmailTakenException {
      return AccountActionResult.emailTaken;
    } catch (e) {
      AppLogger.error('Could not $what', e);
      return AccountActionResult.failed;
    }
  }
}
