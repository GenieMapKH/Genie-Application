import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tilomnov/core/network/network_status.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/feedback/connection_popups.dart';
import 'package:tilomnov/shared/widgets/feedback/load_failure_view.dart';

Widget _app(Widget home, {bool withPopups = false}) {
  final navigatorKey = GlobalKey<NavigatorState>();
  return MaterialApp(
    navigatorKey: navigatorKey,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLanguages.all,
    locale: const Locale('en'),
    builder: withPopups
        ? (_, child) =>
              ConnectionPopups(navigatorKey: navigatorKey, child: child!)
        : null,
    home: Scaffold(body: Center(child: home)),
  );
}

DioException _failure(DioExceptionType type) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  type: type,
);

/// Lets every popup run out its time and leave.
Future<void> _popupsGone(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  final status = NetworkStatus.instance;

  setUp(status.reset);
  tearDown(status.reset);

  group('ConnectionPopups', () {
    testWidgets('offline pops up over the screen, then back online', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const Text('home'), withPopups: true));
      final homeTop = tester.getTopLeft(find.text('home')).dy;

      status.unreachable();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('No internet connection'), findsNothing);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('No internet connection'), findsOneWidget);
      // Over the screen: nothing under it moves.
      expect(tester.getTopLeft(find.text('home')).dy, homeTop);

      status.reachable();
      await tester.pumpAndSettle();
      expect(find.text('No internet connection'), findsNothing);
      expect(find.text('Back online'), findsOneWidget);

      await _popupsGone(tester);
      expect(find.text('Back online'), findsNothing);
    });

    testWidgets('offline has a retry that asks the server at once', (
      tester,
    ) async {
      var probes = 0;
      status.probe = () async => probes++;
      addTearDown(() => status.probe = null);
      await tester.pumpWidget(_app(const Text('home'), withPopups: true));

      status.unreachable();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Retry'));
      await tester.pumpAndSettle();

      expect(probes, 1);
      // Still offline: it says so again.
      expect(find.text('No internet connection'), findsOneWidget);
      await _popupsGone(tester);
      status.reset();
    });

    testWidgets('a dropped request repaired at once shows nothing', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const Text('home'), withPopups: true));

      status.unreachable();
      await tester.pump(const Duration(milliseconds: 500));
      status.reachable();
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('No internet connection'), findsNothing);
      expect(find.text('Back online'), findsNothing);
    });

    testWidgets('slow pops up once, not again for a while', (tester) async {
      await tester.pumpWidget(_app(const Text('home'), withPopups: true));

      for (var i = 0; i < NetworkStatus.slowReadsForWeak; i++) {
        status.slow();
      }
      await tester.pumpAndSettle();
      expect(find.textContaining('Slow connection'), findsOneWidget);
      await _popupsGone(tester);

      status.quick();
      for (var i = 0; i < NetworkStatus.slowReadsForWeak; i++) {
        status.slow();
      }
      await tester.pumpAndSettle();
      expect(find.textContaining('Slow connection'), findsNothing);
      status.quick();
      await _popupsGone(tester);
    });
  });

  group('LoadFailureView', () {
    testWidgets('offline: says so, waits, and retries once back online', (
      tester,
    ) async {
      var retries = 0;
      status.unreachable();
      await tester.pumpWidget(
        _app(
          LoadFailureView(
            error: _failure(DioExceptionType.connectionError),
            message: 'Could not load properties',
            onRetry: () => retries++,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 3));

      expect(find.text('Could not load properties'), findsNothing);
      expect(
        find.textContaining('This page will load by itself'),
        findsOneWidget,
      );
      expect(find.text('Waiting for network…'), findsOneWidget);

      status.reachable();
      await tester.pump();
      expect(retries, 1);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('slow: tells the user their connection is too slow', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          LoadFailureView(
            error: _failure(DioExceptionType.receiveTimeout),
            message: 'Could not load properties',
            onRetry: () {},
          ),
        ),
      );

      expect(find.text('Your connection is too slow'), findsOneWidget);
    });

    testWidgets('another failure keeps the screen message, no auto retry', (
      tester,
    ) async {
      var retries = 0;
      status.unreachable();
      await tester.pumpWidget(
        _app(
          LoadFailureView(
            error: StateError('bad data'),
            message: 'Could not load properties',
            onRetry: () => retries++,
          ),
        ),
      );
      expect(find.text('Could not load properties'), findsOneWidget);

      status.reachable();
      await tester.pump();
      expect(retries, 0);

      await tester.tap(find.text('Retry'));
      expect(retries, 1);
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
