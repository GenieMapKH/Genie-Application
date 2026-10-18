import 'package:genie/core/logging/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/features/auth/data/google_sign_in_service.dart';
import 'package:genie/features/auth/data/repositories/auth_repository.dart';

final loginControllerProvider =
    StateNotifierProvider<LoginController, AsyncValue<bool>>((ref) {
      return LoginController(
        ref.watch(authServiceProvider),
        ref.watch(googleSignInServiceProvider),
      );
    });

class LoginController extends StateNotifier<AsyncValue<bool>> {
  final AuthService _authService;
  final GoogleSignInService _googleSignIn;

  LoginController(this._authService, this._googleSignIn)
    : super(const AsyncData(false));

  void reset() {
    state = const AsyncData(false);
  }

  /// [afterSignIn] runs once the server accepted the password, before the
  /// sign-in counts as done (the page is still showing): it gets the
  /// password, e.g. to unlock the chat keys. Its own problems never fail
  /// the sign-in.
  Future<bool> login(
    String identifier,
    String password, {
    Future<void> Function(String password)? afterSignIn,
  }) async {
    state = const AsyncLoading();
    try {
      await _authService.login(identifier, password);
      try {
        await afterSignIn?.call(password);
      } catch (e, st) {
        AppLogger.error('After sign-in step failed', e, st);
      }
      state = const AsyncData(true);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> googleLogin({bool forceAccountSelection = false}) async {
    state = const AsyncLoading();
    try {
      final user = await _googleSignIn.signIn(
        forceAccountSelection: forceAccountSelection,
      );
      if (user == null) {
        // User canceled account picker
        state = const AsyncData(false);
        return false;
      }

      await _authService.firebaseLogin(user);
      state = const AsyncData(true);
      return true;
    } catch (e, st) {
      AppLogger.debug('Google login error: $e\n$st');
      state = AsyncError(e, st);
      return false;
    }
  }
}
