import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/auth/data/phone_verification_service.dart';

class _PhoneRequest {
  final PhoneVerificationCompleted completed;
  final PhoneVerificationFailed failed;
  final PhoneCodeSent sent;
  final PhoneCodeAutoRetrievalTimeout timeout;
  final int? resendToken;

  _PhoneRequest(
    this.completed,
    this.failed,
    this.sent,
    this.timeout,
    this.resendToken,
  );
}

class _Auth implements FirebaseAuth {
  final requests = <_PhoneRequest>[];
  final credentials = <AuthCredential>[];
  final user = _User();
  int signOuts = 0;
  Object? signInError;
  Object? requestError;

  @override
  Future<void> verifyPhoneNumber({
    String? phoneNumber,
    PhoneMultiFactorInfo? multiFactorInfo,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
    String? autoRetrievedSmsCodeForTesting,
    Duration timeout = const Duration(seconds: 30),
    int? forceResendingToken,
    MultiFactorSession? multiFactorSession,
  }) async {
    if (requestError != null) throw requestError!;
    requests.add(
      _PhoneRequest(
        verificationCompleted,
        verificationFailed,
        codeSent,
        codeAutoRetrievalTimeout,
        forceResendingToken,
      ),
    );
  }

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    if (signInError != null) throw signInError!;
    credentials.add(credential);
    return _Credential(user);
  }

  @override
  Future<void> signOut() async {
    signOuts++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _User implements User {
  Object? error;

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    if (error != null) throw error!;
    return 'firebase-phone-token';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Credential implements UserCredential {
  _Credential(this.user);
  @override
  final User user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Auth auth;
  late PhoneVerificationChallenge challenge;
  setUp(() {
    auth = _Auth();
    challenge = PhoneVerificationService(auth: auth).challenge('+85512345678');
  });

  test(
    'manual SMS confirmation returns proof and clears the Firebase session',
    () async {
      final sent = challenge.send();
      auth.requests.single.sent('id-1', 7);
      expect(await sent, isNull);
      expect(await challenge.confirm('123456'), 'firebase-phone-token');
      final credential = auth.credentials.single as PhoneAuthCredential;
      expect(credential.verificationId, 'id-1');
      expect(credential.smsCode, '123456');
      expect(auth.signOuts, 1);
    },
  );

  test(
    'resend uses its token and ignores the previous request timeout',
    () async {
      final first = challenge.send();
      auth.requests.first.sent('id-1', 7);
      await first;
      final second = challenge.send();
      expect(auth.requests.last.resendToken, 7);
      auth.requests.last.sent('id-2', 8);
      await second;
      auth.requests.first.timeout('id-1');
      await challenge.confirm('654321');
      expect(
        (auth.credentials.single as PhoneAuthCredential).verificationId,
        'id-2',
      );
    },
  );

  test('automatic verification works both before and after codeSent', () async {
    final sent = challenge.send();
    auth.requests.single.completed(
      PhoneAuthProvider.credential(
        verificationId: 'automatic',
        smsCode: '123456',
      ),
    );
    expect(await sent, 'firebase-phone-token');
    expect(await challenge.automaticProof, 'firebase-phone-token');

    final later = PhoneVerificationService(
      auth: auth,
    ).challenge('+85512345678');
    final pending = later.send();
    auth.requests.last.sent('id-2', 8);
    await pending;
    auth.requests.last.completed(
      PhoneAuthProvider.credential(
        verificationId: 'automatic-2',
        smsCode: '123456',
      ),
    );
    expect(await later.automaticProof, 'firebase-phone-token');
  });

  test('closed challenge ignores late automatic verification', () async {
    final sent = challenge.send();
    auth.requests.single.sent('id-1', 7);
    await sent;
    challenge.close();
    auth.requests.single.completed(
      PhoneAuthProvider.credential(verificationId: 'id-1', smsCode: '123456'),
    );
    await Future<void>.delayed(Duration.zero);
    expect(auth.credentials, isEmpty);
  });

  test('Firebase request and callback errors reach the caller', () async {
    auth.requestError = FirebaseAuthException(code: 'network-request-failed');
    await expectLater(challenge.send(), throwsA(isA<FirebaseAuthException>()));
    auth.requestError = null;
    final sent = challenge.send();
    final failure = expectLater(sent, throwsA(isA<FirebaseAuthException>()));
    auth.requests.last.failed(FirebaseAuthException(code: 'too-many-requests'));
    await failure;
  });

  test(
    'failed token retrieval still clears Firebase and permits retry',
    () async {
      final sent = challenge.send();
      auth.requests.single.sent('id-1', 7);
      await sent;
      auth.user.error = StateError('token retrieval failed');
      await expectLater(challenge.confirm('123456'), throwsStateError);
      expect(auth.signOuts, 1);
      auth.user.error = null;
      expect(await challenge.confirm('123456'), 'firebase-phone-token');
    },
  );
}
