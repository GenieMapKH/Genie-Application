import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/auth/data/google_sign_in_service.dart';
import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';
import 'package:tilomnov/features/auth/presentation/view_models/login_controller.dart';

class _AcceptingAuthService extends AuthService {
  _AcceptingAuthService() : super(Dio());

  @override
  Future<void> login(String identifier, String password) async {}
}

class _RefusingAuthService extends AuthService {
  _RefusingAuthService() : super(Dio());

  @override
  Future<void> login(String identifier, String password) async =>
      throw Exception('Invalid credentials');
}

void main() {
  test('an accepted sign-in counts as done', () async {
    final controller = LoginController(
      _AcceptingAuthService(),
      GoogleSignInService(),
    );
    addTearDown(controller.dispose);

    final ok = await controller.login('dara@example.com', 'secret-password');

    expect(ok, isTrue);
    expect(controller.state.value, isTrue);
  });

  test('a refused sign-in reports the error', () async {
    final controller = LoginController(
      _RefusingAuthService(),
      GoogleSignInService(),
    );
    addTearDown(controller.dispose);

    final ok = await controller.login('dara@example.com', 'wrong');

    expect(ok, isFalse);
    expect(controller.state, isA<AsyncError<bool>>());
  });
}
