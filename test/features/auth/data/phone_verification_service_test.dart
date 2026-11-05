import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/auth/data/phone_verification_service.dart';

void main() {
  PhoneVerificationFailure failureFor(String code) =>
      PhoneVerificationService.failureOf(
        FirebaseAuthException(code: code),
      ).failure;

  test('tells the cases a screen explains apart', () {
    expect(
      failureFor('invalid-phone-number'),
      PhoneVerificationFailure.invalidNumber,
    );
    expect(
      failureFor('invalid-verification-code'),
      PhoneVerificationFailure.wrongCode,
    );
    expect(failureFor('session-expired'), PhoneVerificationFailure.codeExpired);
    expect(
      failureFor('too-many-requests'),
      PhoneVerificationFailure.tooManyAttempts,
    );
    expect(
      failureFor('network-request-failed'),
      PhoneVerificationFailure.network,
    );
    expect(
      failureFor('operation-not-allowed'),
      PhoneVerificationFailure.unavailable,
    );
  });

  test('keeps the Firebase code of anything else, for the logs', () {
    final error = PhoneVerificationService.failureOf(
      FirebaseAuthException(code: 'internal-error'),
    );
    expect(error.failure, PhoneVerificationFailure.unknown);
    expect(error.detail, 'internal-error');
  });

  test('reads Firebase refusing to send the SMS as "unavailable"', () {
    final error = PhoneVerificationService.failureOf(
      FirebaseAuthException(
        code: 'unknown',
        message: 'An internal error has occurred. [ Error code:39 ]',
      ),
    );
    expect(error.failure, PhoneVerificationFailure.unavailable);
  });
}
