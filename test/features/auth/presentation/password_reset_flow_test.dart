import 'package:flutter_test/flutter_test.dart';
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeAuth auth;
  late PasswordResetFlow flow;

  setUp(() {
    auth = _FakeAuth();
    flow = PasswordResetFlow(auth);
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
}
