import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/features/auth/data/google_sign_in_service.dart';
import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';

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

  Future<bool> login(String identifier, String password) async {
    state = const AsyncLoading();
    try {
      await _authService.login(identifier, password);
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
