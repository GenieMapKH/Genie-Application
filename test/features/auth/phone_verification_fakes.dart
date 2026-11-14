import 'dart:async';

import 'package:tilomnov/features/auth/data/phone_verification_service.dart';

class FakePhoneVerification extends PhoneVerificationService {
  final challenges = <FakePhoneChallenge>[];

  @override
  PhoneVerificationChallenge challenge(String phone) {
    final challenge = FakePhoneChallenge(phone);
    challenges.add(challenge);
    return challenge;
  }
}

class FakePhoneChallenge implements PhoneVerificationChallenge {
  FakePhoneChallenge(this.phone);

  @override
  final String phone;
  final automatic = Completer<String?>();
  int sends = 0;
  bool closed = false;

  @override
  Future<String?> get automaticProof => automatic.future;

  @override
  Future<String?> send() async {
    sends++;
    return null;
  }

  @override
  Future<String> confirm(String code) async => 'phone-proof';

  @override
  void close() => closed = true;
}
