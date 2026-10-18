import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/auth/data/google_sign_in_service.dart';
import 'package:genie/features/auth/data/repositories/auth_repository.dart';
import 'package:genie/features/auth/presentation/view_models/login_controller.dart';

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
  test('hands the password on before the sign-in counts as done', () async {
    final controller = LoginController(
      _AcceptingAuthService(),
      GoogleSignInService(),
    );
    addTearDown(controller.dispose);
    final seen = <(String, bool)>[];

    final ok = await controller.login(
      'dara@example.com',
      'secret-password',
      afterSignIn: (password) async =>
          seen.add((password, controller.state.isLoading)),
    );

    expect(ok, isTrue);
    expect(seen, [('secret-password', true)]);
    expect(controller.state.value, isTrue);
  });

  test('a failing step after sign-in never fails the sign-in', () async {
    final controller = LoginController(
      _AcceptingAuthService(),
      GoogleSignInService(),
    );
    addTearDown(controller.dispose);

    final ok = await controller.login(
      'dara@example.com',
      'secret-password',
      afterSignIn: (_) async => throw Exception('chat server down'),
    );

    expect(ok, isTrue);
    expect(controller.state.value, isTrue);
  });

  test('a refused sign-in hands nothing on', () async {
    final controller = LoginController(
      _RefusingAuthService(),
      GoogleSignInService(),
    );
    addTearDown(controller.dispose);
    var called = false;

    final ok = await controller.login(
      'dara@example.com',
      'wrong',
      afterSignIn: (_) async => called = true,
    );

    expect(ok, isFalse);
    expect(called, isFalse);
  });
}
