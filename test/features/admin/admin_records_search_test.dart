import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/admin/presentation/admin_records_page.dart';
import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';

import '../../support/test_app.dart';

void main() {
  testWidgets(
    'search debounces, resets pagination, preserves tier and clears',
    (tester) async {
      final queries = <Map<String, dynamic>>[];
      final server = StubServer((request) {
        queries.add(Map.of(request.queryParameters));
        final searching = request.queryParameters['q'] != null;
        return (
          200,
          jsonEncode({
            'items': [
              {'userId': searching ? 'matched' : 'initial', 'tier': 'gold'},
            ],
            'nextOffset': request.queryParameters['offset'] == 0 ? 50 : null,
          }),
        );
      });
      await pumpTestApp(
        tester,
        const AdminRecordsPage(
          section: 'subscriptions',
          title: 'Subscriptions',
          tier: 'gold',
        ),
        overrides: [apiClientProvider.overrideWithValue(server.dio)],
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Load more'));
      await tester.pumpAndSettle();
      expect(queries.last['offset'], 50);

      await tester.enterText(find.byType(TextField), 'g');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), ' gold ');
      await tester.pump(const Duration(milliseconds: 300));
      expect(queries, hasLength(2));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(queries.last, {
        'section': 'subscriptions',
        'offset': 0,
        'tier': 'gold',
        'q': 'gold',
      });
      expect(find.text('Search results'), findsOneWidget);

      await tester.tap(find.text('Load more'));
      await tester.pumpAndSettle();
      expect(queries.last, {
        'section': 'subscriptions',
        'offset': 50,
        'tier': 'gold',
        'q': 'gold',
      });
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(queries.last, {
        'section': 'subscriptions',
        'offset': 0,
        'tier': 'gold',
      });
      expect(find.text('Browse Subscriptions'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final section in [
    'active-users',
    'all-users',
    'new-users',
    'active-listings',
    'all-listings',
    'new-listings',
    'reports',
    'leads',
    'subscriptions',
    'successful-payments',
    'pending-payments',
  ]) {
    testWidgets('$section searches the API and shows an empty result', (
      tester,
    ) async {
      final queries = <Map<String, dynamic>>[];
      final server = StubServer((request) {
        queries.add(Map.of(request.queryParameters));
        return (200, '{"items":[],"nextOffset":null}');
      });
      await pumpTestApp(
        tester,
        AdminRecordsPage(section: section, title: 'Records'),
        overrides: [apiClientProvider.overrideWithValue(server.dio)],
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Missing');
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      expect(queries.last, {'section': section, 'offset': 0, 'q': 'Missing'});
      expect(find.text('No records found'), findsOneWidget);
      expect(find.text('Try a different name, keyword or ID.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
