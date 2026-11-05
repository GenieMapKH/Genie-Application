import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/auth/data/phone_verification_service.dart';
import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';
import 'package:tilomnov/features/auth/presentation/view_models/password_reset_flow.dart';

/// Records what reached the server.
class _FakeAuth implements AuthService {
  final calls = <String>[];
  bool codeIsRight = true;

  @override
  Future<void> forgotPassword(String email) async => calls.add('forgot $email');

  @override
  Future<bool> verifyOtp(String email, String otp) async {
    calls.add('verify $email $otp');
    return codeIsRight;
  }

  @override
  Future<void> resetPassword(String email, String otp, String password) async =>
      calls.add('reset $email $otp $password');

  @override
  Future<void> resetPasswordWithPhone(String idToken, String password) async =>
      calls.add('reset-phone $idToken $password');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePhones implements PhoneVerificationService {
  PhoneCodeRequest next = const PhoneCodeSent('session-1', 7);
  final requested = <(String, int?)>[];

  @override
  Future<PhoneCodeRequest> requestCode(String phone, {int? resendToken}) async {
    requested.add((phone, resendToken));
    return next;
  }

  @override
  Future<String> confirm(String verificationId, String smsCode) async =>
      'token-for-$verificationId-$smsCode';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeAuth auth;
  late _FakePhones phones;
  late PasswordResetFlow flow;

  setUp(() {
    auth = _FakeAuth();
    phones = _FakePhones();
    flow = PasswordResetFlow(auth, phones);
  });

  group('by email', () {
    test('sends the code, checks it, then resets with it', () async {
      final target = await flow.sendEmailCode('dara@example.com');
      final proof = await flow.checkCode(target, '123456');
      await flow.setNewPassword(proof!, 'new-password');

      expect(auth.calls, [
        'forgot dara@example.com',
        'verify dara@example.com 123456',
        'reset dara@example.com 123456 new-password',
      ]);
    });

    test('gives no proof for a wrong code', () async {
      auth.codeIsRight = false;
      expect(
        await flow.checkCode(const EmailResetTarget('a@b.c'), '000000'),
        isNull,
      );
    });
  });

  group('by phone', () {
    test(
      'texts the code, turns it into a token, then resets with the token',
      () async {
        final outcome = await flow.sendPhoneCode('+85512345678');
        final proof = await flow.checkCode(outcome.target!, '123456');
        await flow.setNewPassword(proof!, 'new-password');

        expect(phones.requested, [('+85512345678', null)]);
        expect(auth.calls, [
          'reset-phone token-for-session-1-123456 new-password',
        ]);
      },
    );

    test('skips the code screen when Android read the SMS by itself', () async {
      phones.next = const PhoneAlreadyVerified('auto-token');

      final outcome = await flow.sendPhoneCode('+85512345678');

      expect(outcome.target, isNull);
      expect((outcome.proof! as PhoneCodeProof).idToken, 'auto-token');
    });

    test('resends with the token Firebase gave for it', () async {
      await flow.resend(const PhoneResetTarget('+85512345678', 'session-1', 7));
      expect(phones.requested, [('+85512345678', 7)]);
    });
  });
}
