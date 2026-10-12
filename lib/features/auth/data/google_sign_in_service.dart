import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

final googleSignInServiceProvider = Provider<GoogleSignInService>(
  (ref) => GoogleSignInService(),
);

/// Signing in with a Google account, through Firebase.
class GoogleSignInService {
  /// The web client that Firebase checks Google sign-ins against. A public
  /// identifier, not a secret.
  static const _serverClientId =
      '67344886415-o6541mjvj1skaoibkrp9rcj6nnu2aekk.apps.googleusercontent.com';

  /// Shows Google's account picker and signs in to Firebase with the choice.
  /// Returns null when the user closes the picker.
  ///
  /// With [forceAccountSelection] the picker always appears, instead of
  /// silently reusing the Google account chosen last time.
  Future<User?> signIn({bool forceAccountSelection = false}) async {
    final googleSignIn = GoogleSignIn(serverClientId: _serverClientId);
    if (forceAccountSelection) {
      await googleSignIn.signOut();
    }

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final userCredential = await FirebaseAuth.instance.signInWithCredential(
      GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      ),
    );
    return userCredential.user;
  }

  /// The Google account's profile photo; `url` is null when it has none.
  /// Signs in with Google first when this device no longer has that
  /// session, and returns null when the user closes the picker.
  Future<({String? url})?> profilePhoto() async {
    final user = FirebaseAuth.instance.currentUser ?? await signIn();
    return user == null ? null : (url: user.photoURL);
  }

  /// Signs in with Google again and returns the resulting Firebase ID token:
  /// proof, for a few minutes, that the account's owner is holding the phone.
  /// Null when the user closes the picker.
  Future<String?> freshIdToken() async {
    final user = await signIn();
    return user?.getIdToken(true);
  }
}
