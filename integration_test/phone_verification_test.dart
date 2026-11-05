// Runs the real SMS check on a device against a Firebase test number (set
// one in Firebase console > Authentication > Sign-in method > Phone):
//
//   flutter test integration_test/phone_verification_test.dart \
//     --dart-define=TEST_PHONE=+85510000000 --dart-define=TEST_CODE=123456
//
// Firebase's app check (Play Integrity, else reCAPTCHA) is skipped, as Firebase
// allows for test numbers: a build installed over USB is not from Google Play,
// so Play Integrity refuses it. Add --dart-define=APP_CHECK=on to keep the
// check, e.g. for a build installed from a Play testing track.
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tilomnov/features/auth/data/phone_verification_service.dart';
import 'package:tilomnov/firebase_options.dart';

const _phone = String.fromEnvironment('TEST_PHONE');
const _code = String.fromEnvironment('TEST_CODE');
const _appCheck = String.fromEnvironment('APP_CHECK') == 'on';

PhoneVerificationService _service() => PhoneVerificationService(
  auth: () async {
    final auth = await PhoneVerificationService.firebaseAuth();
    await auth.setSettings(appVerificationDisabledForTesting: !_appCheck);
    return auth;
  },
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  });

  testWidgets('texts a code and turns it into a token naming the number', (
    tester,
  ) async {
    final service = _service();

    final request = await service.requestCode(_phone);
    final token = switch (request) {
      PhoneCodeSent(:final verificationId) => await service.confirm(
        verificationId,
        _code,
      ),
      PhoneAlreadyVerified(:final idToken) => idToken,
    };

    final claims =
        jsonDecode(
              utf8.decode(
                base64Url.decode(base64Url.normalize(token.split('.')[1])),
              ),
            )
            as Map<String, dynamic>;
    expect(claims['phone_number'], _phone);
  }, skip: _phone.isEmpty || _code.isEmpty);

  testWidgets('refuses a wrong code', (tester) async {
    final service = _service();
    final request = await service.requestCode(_phone);
    if (request is! PhoneCodeSent) return;

    await expectLater(
      service.confirm(
        request.verificationId,
        _code == '000000' ? '111111' : '000000',
      ),
      throwsA(
        isA<PhoneVerificationException>().having(
          (e) => e.failure,
          'failure',
          PhoneVerificationFailure.wrongCode,
        ),
      ),
    );
  }, skip: _phone.isEmpty || _code.isEmpty);
}
