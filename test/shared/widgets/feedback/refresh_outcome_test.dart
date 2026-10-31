import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tilomnov/core/network/network_status.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/feedback/refresh_outcome.dart';

/// A screen whose button reports a pull-to-refresh that went [ok].
Widget _screen({required bool ok, required VoidCallback onRetry}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLanguages.all,
    locale: const Locale('en'),
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showRefreshOutcome(
            context,
            ok: ok,
            failedMessage: 'Your feed could not be loaded.',
            onRetry: onRetry,
          ),
          child: const Text('refresh'),
        ),
      ),
    ),
  );
}

Future<void> _popupsGone(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  final status = NetworkStatus.instance;

  setUp(status.reset);
  tearDown(status.reset);

  testWidgets('offline: no internet, with a retry, not the screen message', (
    tester,
  ) async {
    var retries = 0;
    status.unreachable();
    await tester.pumpWidget(_screen(ok: true, onRetry: () => retries++));

    await tester.tap(find.text('refresh'));
    await tester.pumpAndSettle();
    expect(find.text('No internet connection'), findsOneWidget);
    expect(find.text('Your feed could not be loaded.'), findsNothing);

    await tester.tap(find.byTooltip('Retry'));
    await tester.pumpAndSettle();
    expect(retries, 1);
    expect(find.text('No internet connection'), findsNothing);
    status.reset();
  });

  testWidgets('online but failed: the screen message', (tester) async {
    await tester.pumpWidget(_screen(ok: false, onRetry: () {}));

    await tester.tap(find.text('refresh'));
    await tester.pumpAndSettle();
    expect(find.text('Your feed could not be loaded.'), findsOneWidget);
    expect(find.byTooltip('Retry'), findsNothing);
    await _popupsGone(tester);
  });

  testWidgets('worked: nothing to say', (tester) async {
    await tester.pumpWidget(_screen(ok: true, onRetry: () {}));

    await tester.tap(find.text('refresh'));
    await tester.pumpAndSettle();
    expect(find.byType(Overlay), findsOneWidget);
    expect(find.text('No internet connection'), findsNothing);
    expect(find.text('Your feed could not be loaded.'), findsNothing);
  });
}
