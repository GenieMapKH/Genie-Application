import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';

sealed class PasswordResetTarget {
  const PasswordResetTarget();
}

class EmailResetTarget extends PasswordResetTarget {
  final String email;
  const EmailResetTarget(this.email);
}

sealed class PasswordResetProof {
  const PasswordResetProof();
}

class EmailCodeProof extends PasswordResetProof {
  final String email;
  final String otp;
  const EmailCodeProof(this.email, this.otp);
}

final passwordResetFlowProvider = Provider<PasswordResetFlow>(
  (ref) => PasswordResetFlow(ref.read(authServiceProvider)),
);

/// Password recovery requires a proven email; contact phone numbers are unverified.
class PasswordResetFlow {
  final AuthService _auth;
  PasswordResetFlow(this._auth);

  Future<EmailResetTarget> sendEmailCode(String email) async {
    await _auth.forgotPassword(email);
    return EmailResetTarget(email);
  }

  Future<EmailResetTarget> resend(PasswordResetTarget target) async =>
      switch (target) {
        EmailResetTarget(:final email) => await sendEmailCode(email),
      };
  Future<PasswordResetProof?> checkCode(
    PasswordResetTarget target,
    String code,
  ) async => switch (target) {
    EmailResetTarget(:final email) =>
      await _auth.verifyOtp(email, code) ? EmailCodeProof(email, code) : null,
  };
  Future<void> setNewPassword(PasswordResetProof proof, String password) =>
      switch (proof) {
        EmailCodeProof(:final email, :final otp) => _auth.resetPassword(
          email,
          otp,
          password,
        ),
      };
}
