import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/core/logging/app_logger.dart';

final phoneVerificationServiceProvider = Provider<PhoneVerificationService>(
  (ref) => PhoneVerificationService(),
);

/// One SMS challenge, including Android's automatic verification and resend.
class PhoneVerificationService {
  PhoneVerificationService({FirebaseAuth? auth}) : _auth = auth;

  final FirebaseAuth? _auth;

  PhoneVerificationChallenge challenge(String phone) =>
      PhoneVerificationChallenge(_auth ?? FirebaseAuth.instance, phone);
}

class PhoneVerificationChallenge {
  PhoneVerificationChallenge(this._auth, this.phone);

  final FirebaseAuth _auth;
  final String phone;
  final _automatic = Completer<String?>();
  String? _verificationId;
  int? _resendToken;
  bool _closed = false;
  int _request = 0;
  Future<String>? _proofInFlight;

  Future<String?> get automaticProof => _automatic.future;

  void close() => _closed = true;

  Future<String?> send() async {
    final sent = Completer<String?>();
    final request = ++_request;
    unawaited(
      _auth
          .verifyPhoneNumber(
            phoneNumber: phone,
            forceResendingToken: _resendToken,
            verificationCompleted: (credential) async {
              if (_closed || request != _request) return;
              try {
                final proof = await _proof(credential);
                if (!_automatic.isCompleted) _automatic.complete(proof);
                if (!sent.isCompleted) sent.complete(proof);
              } catch (error, stack) {
                if (!sent.isCompleted) {
                  sent.completeError(error, stack);
                } else {
                  AppLogger.error(
                    'Automatic SMS verification failed; enter the code manually',
                    error,
                    stack,
                  );
                }
              }
            },
            verificationFailed: (error) {
              if (!sent.isCompleted) sent.completeError(error);
            },
            codeSent: (id, token) {
              if (_closed || request != _request) return;
              _verificationId = id;
              _resendToken = token;
              if (!sent.isCompleted) sent.complete(null);
            },
            codeAutoRetrievalTimeout: (id) {
              if (_closed || request != _request) return;
              _verificationId = id;
              if (!sent.isCompleted) sent.complete(null);
            },
          )
          .catchError((Object error, StackTrace stack) {
            if (!sent.isCompleted) sent.completeError(error, stack);
          }),
    );
    return sent.future;
  }

  Future<String> confirm(String code) => _proof(
    PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: code,
    ),
  );

  Future<String> _proof(PhoneAuthCredential credential) => _proofInFlight ??=
      _readProof(credential).whenComplete(() => _proofInFlight = null);

  Future<String> _readProof(PhoneAuthCredential credential) async {
    final result = await _auth.signInWithCredential(credential);
    try {
      final token = await result.user?.getIdToken(true);
      if (token == null) throw StateError('Missing Firebase phone proof');
      return token;
    } finally {
      // SMS proves a contact; only the backend can establish an app session.
      await _auth.signOut();
    }
  }
}
