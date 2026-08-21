import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/core/services/auth_service.dart';

final loginControllerProvider = StateNotifierProvider<LoginController, AsyncValue<void>>((ref) {
  return LoginController(ref.watch(authServiceProvider));
});

class LoginController extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;

  LoginController(this._authService) : super(const AsyncData(null));

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      await _authService.login(email, password);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> googleLogin(dynamic googleUser) async {
    // This is a placeholder since the original code didn't fully implement it
    // but we use the same state management
    state = const AsyncLoading();
    try {
      await _authService.firebaseLogin(googleUser);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
