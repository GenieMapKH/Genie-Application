import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/firebase_options.dart';

final phoneVerificationServiceProvider = Provider<PhoneVerificationService>(
  (ref) => PhoneVerificationService(),
);

/// Why a phone could not be verified, in terms the screen can explain.
enum PhoneVerificationFailure {
  invalidNumber,
  wrongCode,
  codeExpired,
  tooManyAttempts,
  network,

  /// SMS sign-in is switched off for the Firebase project, or not allowed for
  /// this country.
  unavailable,
  unknown,
}

class PhoneVerificationException implements Exception {
  final PhoneVerificationFailure failure;
  final String? detail;

  const PhoneVerificationException(this.failure, [this.detail]);

  @override
  String toString() => 'PhoneVerificationException($failure, $detail)';
}

/// What asking for a code led to.
sealed class PhoneCodeRequest {
  const PhoneCodeRequest();
}

/// A code was texted: ask the user for it, then call [PhoneVerificationService.confirm].
class PhoneCodeSent extends PhoneCodeRequest {
  final String verificationId;

  /// Pass back to [PhoneVerificationService.requestCode] to send it again.
  final int? resendToken;

  const PhoneCodeSent(this.verificationId, this.resendToken);
}

/// Android read the code by itself: the number is verified already.
class PhoneAlreadyVerified extends PhoneCodeRequest {
  final String idToken;

  const PhoneAlreadyVerified(this.idToken);
}

/// Proves the user holds a phone number. Firebase texts a code; once it is
/// typed, the result is a Firebase ID token naming the number, which the
/// backend checks before trusting it.
///
/// Runs on a Firebase app of its own, so it never replaces the Google
/// sign-in kept by the default one (the profile photo reads it).
class PhoneVerificationService {
  static const _appName = 'phone-verification';
  static const _codeTimeout = Duration(seconds: 60);

  final Future<FirebaseAuth> Function() _auth;

  PhoneVerificationService({Future<FirebaseAuth> Function()? auth})
    : _auth = auth ?? firebaseAuth;

  /// The Firebase sign-in of this service's own Firebase app.
  static Future<FirebaseAuth> firebaseAuth() async {
    final app = Firebase.apps.any((app) => app.name == _appName)
        ? Firebase.app(_appName)
        : await Firebase.initializeApp(
            name: _appName,
            options: DefaultFirebaseOptions.currentPlatform,
          );
    return FirebaseAuth.instanceFor(app: app);
  }

  /// Texts a code to [phoneNumber] (E.164, e.g. `+85512345678`).
  Future<PhoneCodeRequest> requestCode(
    String phoneNumber, {
    int? resendToken,
  }) async {
    final auth = await _auth();
    final result = Completer<PhoneCodeRequest>();

    await auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: _codeTimeout,
      forceResendingToken: resendToken,
      codeSent: (verificationId, token) {
        if (!result.isCompleted) {
          result.complete(PhoneCodeSent(verificationId, token));
        }
      },
      verificationCompleted: (credential) async {
        if (result.isCompleted) return;
        try {
          result.complete(
            PhoneAlreadyVerified(await _tokenOf(auth, credential)),
          );
        } catch (error, stackTrace) {
          if (!result.isCompleted) result.completeError(error, stackTrace);
        }
      },
      verificationFailed: (error) {
        AppLogger.error('Phone verification failed', error);
        if (!result.isCompleted) result.completeError(failureOf(error));
      },
      codeAutoRetrievalTimeout: (_) {},
    );
    return result.future;
  }

  /// Checks the [smsCode] the user typed. Returns the Firebase ID token.
  Future<String> confirm(String verificationId, String smsCode) async {
    final auth = await _auth();
    return _tokenOf(
      auth,
      PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      ),
    );
  }

  /// The token is all that is needed: the Firebase session ends right away.
  Future<String> _tokenOf(
    FirebaseAuth auth,
    PhoneAuthCredential credential,
  ) async {
    try {
      final signedIn = await auth.signInWithCredential(credential);
      final token = await signedIn.user?.getIdToken(true);
      if (token == null) {
        throw const PhoneVerificationException(
          PhoneVerificationFailure.unknown,
          'No ID token',
        );
      }
      return token;
    } on FirebaseAuthException catch (error) {
      throw failureOf(error);
    } finally {
      await auth.signOut();
    }
  }

  /// Firebase's error codes, as the few cases a screen tells apart.
  static PhoneVerificationException failureOf(FirebaseAuthException error) {
    // Firebase refusing to text a real number (billing, region or
    // anti-abuse) comes as an "internal error" with this code in its message.
    if ((error.message ?? '').contains('Error code:39')) {
      return PhoneVerificationException(
        PhoneVerificationFailure.unavailable,
        'sms-refused (${error.code})',
      );
    }
    final failure = switch (error.code) {
      'invalid-phone-number' ||
      'missing-phone-number' => PhoneVerificationFailure.invalidNumber,
      'invalid-verification-code' ||
      'missing-verification-code' => PhoneVerificationFailure.wrongCode,
      'session-expired' ||
      'code-expired' => PhoneVerificationFailure.codeExpired,
      'too-many-requests' ||
      'quota-exceeded' => PhoneVerificationFailure.tooManyAttempts,
      'network-request-failed' => PhoneVerificationFailure.network,
      'operation-not-allowed' ||
      'app-not-authorized' => PhoneVerificationFailure.unavailable,
      _ => PhoneVerificationFailure.unknown,
    };
    return PhoneVerificationException(failure, error.code);
  }
}
