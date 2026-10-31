import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tilomnov/core/errors/app_exceptions.dart';
import 'package:tilomnov/core/network/network_status.dart';
import 'package:tilomnov/features/auth/presentation/auth_error_message.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/feedback/failure_message.dart';

const _fallback = 'Could not save your changes.';

DioException _dio(DioExceptionType type, {int? status}) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    type: type,
    response: status == null
        ? null
        : Response(requestOptions: options, statusCode: status),
  );
}

void main() {
  final l10n = lookupAppLocalizations(AppLanguages.english);
  final status = NetworkStatus.instance;

  setUp(status.reset);
  tearDown(status.reset);

  String message(Object? error) =>
      failureMessage(l10n, error: error, fallback: _fallback);

  test('a request that could not connect says there is no internet', () {
    expect(
      message(_dio(DioExceptionType.connectionError)),
      l10n.failureOffline,
    );
    expect(
      message(_dio(DioExceptionType.connectionTimeout)),
      l10n.failureOffline,
    );
  });

  test('an answer that took too long says the connection is slow', () {
    expect(message(_dio(DioExceptionType.receiveTimeout)), l10n.failureSlow);
  });

  test('a 5xx says the server is in trouble', () {
    expect(
      message(_dio(DioExceptionType.badResponse, status: 503)),
      l10n.failureServer,
    );
  });

  test('a refusal from the server keeps the action\'s own message', () {
    expect(message(_dio(DioExceptionType.badResponse, status: 400)), _fallback);
  });

  test('without the error, the connection state tells an offline failure', () {
    expect(message(null), _fallback);
    status.unreachable();
    expect(message(null), l10n.failureOffline);
    status.reachable(status: 503);
    expect(message(null), l10n.failureServer);
    status.reachable(status: 200);
    expect(message(null), _fallback);
    // A real error that is not the connection's keeps the screen's words.
    expect(message(StateError('bad data')), _fallback);
  });

  test('a wrapped error is judged by what was thrown underneath', () {
    final wrapped = NetworkException(
      'timeout',
      cause: _dio(DioExceptionType.receiveTimeout),
    );
    expect(message(wrapped), l10n.failureSlow);
  });

  group('sign-in errors', () {
    test('no internet is said like everywhere else', () {
      final error = NetworkException(
        'no route',
        cause: _dio(DioExceptionType.connectionError),
      );
      expect(authErrorMessage(l10n, error), l10n.failureOffline);
    });

    test('a 5xx says the server is in trouble', () {
      final error = NetworkException(
        'boom',
        code: '502',
        cause: _dio(DioExceptionType.badResponse, status: 502),
      );
      expect(authErrorMessage(l10n, error), l10n.failureServer);
    });

    test('a wrong password is still a wrong password', () {
      const error = AuthException('nope', code: '401');
      expect(authErrorMessage(l10n, error), l10n.authErrorWrongCredentials);
    });
  });
}
