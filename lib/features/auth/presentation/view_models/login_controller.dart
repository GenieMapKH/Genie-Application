import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/features/auth/data/repositories/auth_repository.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

final loginControllerProvider =
    StateNotifierProvider<LoginController, AsyncValue<bool>>((ref) {
      return LoginController(ref.watch(authServiceProvider));
    });

class LoginController extends StateNotifier<AsyncValue<bool>> {
  final AuthService _authService;

  LoginController(this._authService) : super(const AsyncData(false));

  Future<void> login(String identifier, String password) async {
    state = const AsyncLoading();
    try {
      await _authService.login(identifier, password);
      state = const AsyncData(true);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> googleLogin({bool forceAccountSelection = false}) async {
    state = const AsyncLoading();
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId:
            '67344886415-o6541mjvj1skaoibkrp9rcj6nnu2aekk.apps.googleusercontent.com',
      );

      if (forceAccountSelection) {
        await googleSignIn.signOut();
      }

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled account picker
        state = const AsyncData(false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      if (userCredential.user != null) {
        await _authService.firebaseLogin(userCredential.user!);
      }

      state = const AsyncData(true);
    } catch (e, st) {
      print('Google login error: $e\n$st');
      state = AsyncError(e, st);
    }
  }
}

