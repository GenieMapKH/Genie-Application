import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tilomnov/core/network/network_status.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/feedback/offline_banner.dart';

void main() {
  final status = NetworkStatus.instance;
  final navigatorKey = GlobalKey<NavigatorState>();

  Future<void> pumpApp(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigatorKey,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLanguages.all,
      locale: const Locale('en'),
      builder: (_, child) =>
          OfflineBanner(navigatorKey: navigatorKey, child: child!),
      home: const Scaffold(body: Text('home')),
    ),
  );

  tearDown(() => status.reachable());

  testWidgets('opens a dialog after the outage lasts, closes when back', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('No internet connection'), findsNothing);

    status.online.value = false;
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('No internet connection'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    status.reachable();
    await tester.pumpAndSettle();
    expect(find.text('No internet connection'), findsNothing);
  });

  testWidgets('Keep browsing dismisses it and leaves the bar', (tester) async {
    await pumpApp(tester);

    status.online.value = false;
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep browsing'));
    await tester.pumpAndSettle();

    expect(find.text('No internet connection'), findsNothing);
    expect(find.textContaining('You are offline'), findsOneWidget);
  });
}
