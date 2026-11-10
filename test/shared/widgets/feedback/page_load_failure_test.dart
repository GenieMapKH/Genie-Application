import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tilomnov/core/network/network_status.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/feedback/load_failure_view.dart';
import 'package:tilomnov/shared/widgets/feedback/page_load_failure.dart';

final _offline = DioException(
  requestOptions: RequestOptions(path: '/x'),
  type: DioExceptionType.connectionError,
);

/// A tab page: a header of [headerHeight], the failure under it, and the
/// floating navigation bar's [bottomInset] below.
Widget _page({required double headerHeight, double bottomInset = 98}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLanguages.all,
    locale: const Locale('en'),
    home: MediaQuery(
      data: MediaQueryData(
        size: const Size(390, 844),
        padding: EdgeInsets.only(bottom: bottomInset),
      ),
      child: Scaffold(
        body: Column(
          children: [
            SizedBox(height: headerHeight),
            Expanded(
              child: PageLoadFailure(
                error: _offline,
                message: 'Could not load profile',
                onRetry: () {},
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  setUp(NetworkStatus.instance.reset);
  tearDown(NetworkStatus.instance.reset);

  testWidgets('says why, centred above the navigation bar', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_page(headerHeight: 100));
    await tester.pump();

    expect(find.text('No internet connection'), findsOneWidget);
    expect(find.text('Could not load profile'), findsNothing);
    // Between the header (100) and the bar (844 - 98).
    final center = tester.getCenter(find.byType(LoadFailureView));
    expect(center.dy, closeTo((100 + 844 - 98) / 2, 0.5));
    await tester.pump(const Duration(seconds: 3));
  });
}
