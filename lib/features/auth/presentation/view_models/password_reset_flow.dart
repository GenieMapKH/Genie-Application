import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/features/auth/data/phone_verification_service.dart';
import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';

/// Where the reset code was sent, as the code screen needs it.
sealed class PasswordResetTarget {
  const PasswordResetTarget();
}

class EmailResetTarget extends PasswordResetTarget {
  final String email;
  const EmailResetTarget(this.email);
}

class PhoneResetTarget extends PasswordResetTarget {
  /// E.164, e.g. `+85512345678`.
  final String phone;
  final String verificationId;
  final int? resendToken;

  const PhoneResetTarget(this.phone, this.verificationId, this.resendToken);
}

/// What shows the server the user received the code.
sealed class PasswordResetProof {
  const PasswordResetProof();
}

class EmailCodeProof extends PasswordResetProof {
  final String email;
  final String otp;
  const EmailCodeProof(this.email, this.otp);
}

/// A Firebase ID token naming the phone number, from the SMS code.
class PhoneCodeProof extends PasswordResetProof {
  final String idToken;
  const PhoneCodeProof(this.idToken);
}

/// After asking for a code: either it is on its way, or (Android, reading
/// the SMS by itself) the phone is proven already and the code screen is skipped.
typedef CodeRequestOutcome = ({
  PasswordResetTarget? target,
  PasswordResetProof? proof,
});

final passwordResetFlowProvider = Provider<PasswordResetFlow>(
  (ref) => PasswordResetFlow(
    ref.read(authServiceProvider),
    ref.read(phoneVerificationServiceProvider),
  ),
);

/// "Forgot password", by email or by phone: send a code, check it, set the
/// new password. The screens only show the steps; which way the code
/// travels is decided here.
class PasswordResetFlow {
  final AuthService _auth;
  final PhoneVerificationService _phones;

  PasswordResetFlow(this._auth, this._phones);

  Future<EmailResetTarget> sendEmailCode(String email) async {
    await _auth.forgotPassword(email);
    return EmailResetTarget(email);
  }

  /// [phone] in E.164.
  Future<CodeRequestOutcome> sendPhoneCode(
    String phone, {
    int? resendToken,
  }) async {
    final request = await _phones.requestCode(phone, resendToken: resendToken);
    return switch (request) {
      PhoneCodeSent(:final verificationId, :final resendToken) => (
        target: PhoneResetTarget(phone, verificationId, resendToken),
        proof: null,
      ),
      PhoneAlreadyVerified(:final idToken) => (
        target: null,
        proof: PhoneCodeProof(idToken),
      ),
    };
  }

  /// Sends the code again, the same way as the first time.
  Future<CodeRequestOutcome> resend(PasswordResetTarget target) async {
    return switch (target) {
      EmailResetTarget(:final email) => (
        target: await sendEmailCode(email),
        proof: null,
      ),
      PhoneResetTarget(:final phone, :final resendToken) => sendPhoneCode(
        phone,
        resendToken: resendToken,
      ),
    };
  }

  /// The proof for the next step, or null when the server says the email
  /// code is not right.
  Future<PasswordResetProof?> checkCode(
    PasswordResetTarget target,
    String code,
  ) async {
    switch (target) {
      case EmailResetTarget(:final email):
        return await _auth.verifyOtp(email, code)
            ? EmailCodeProof(email, code)
            : null;
      case PhoneResetTarget(:final verificationId):
        return PhoneCodeProof(await _phones.confirm(verificationId, code));
    }
  }

  Future<void> setNewPassword(PasswordResetProof proof, String password) {
    return switch (proof) {
      EmailCodeProof(:final email, :final otp) => _auth.resetPassword(
        email,
        otp,
        password,
      ),
      PhoneCodeProof(:final idToken) => _auth.resetPasswordWithPhone(
        idToken,
        password,
      ),
    };
  }
}
