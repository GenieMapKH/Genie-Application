import 'package:flutter_test/flutter_test.dart';
import 'package:genie/core/observability/error_reporting.dart';
import 'package:sentry/sentry.dart';

void main() {
  test('a report keeps the user id and drops the rest about them', () {
    final event = ErrorReporting.withoutPersonalData(
      SentryEvent(
        user: SentryUser(
          id: 'u-1',
          email: 'dara@example.com',
          ipAddress: '1.2.3.4',
        ),
        request: SentryRequest(
          url: 'https://api.test/auth/login',
          data: {'password': 'hunter2'},
          headers: {'Authorization': 'Bearer abc'},
        ),
      ),
    );

    expect(event.request, isNull);
    expect(event.user?.id, 'u-1');
    expect(event.user?.email, isNull);
    expect(event.user?.ipAddress, isNull);
  });

  test(
    'a test build has no DSN: the app just runs, reporting nothing',
    () async {
      var ran = false;
      expect(ErrorReporting.isEnabled, isFalse);
      await ErrorReporting.run(() => ran = true);
      expect(ran, isTrue);
    },
  );
}
