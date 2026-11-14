import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/admin/data/admin_income.dart';
import 'package:tilomnov/features/admin/data/admin_record.dart';
import 'package:tilomnov/features/admin/presentation/admin_income_chart.dart';
import 'package:tilomnov/features/admin/presentation/admin_record_icon.dart';
import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';
import '../../support/test_app.dart';

AdminIncome _income({bool empty = false}) => AdminIncome.fromJson({
  'subscriptionUsd': empty ? 0 : 8.9,
  'listingUsd': empty ? 0 : 1,
  'days': [
    for (var day = 2; day <= 9; day++)
      {
        'date': '2026-11-${day.toString().padLeft(2, '0')}',
        'subscriptionUsd': !empty && day == 9 ? 8.9 : 0,
        'listingUsd': !empty && day == 9 ? 1 : 0,
      },
  ],
});

void main() {
  test('income model preserves recorded amounts and zero-income dates', () {
    final income = _income();
    expect(income.days, hasLength(8));
    expect(income.days.first.totalUsd, 0);
    expect(income.days.last.totalUsd, closeTo(9.9, .00001));
    expect(income.subscriptionUsd, 8.9);
    expect(income.listingUsd, 1);
  });

  testWidgets('chart exposes daily amounts on tap and handles zero income', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(child: AdminIncomeChart(income: _income())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(r'$8.90'), findsOneWidget);
    expect(find.text(r'$1.00'), findsOneWidget);
    final bar = find.byWidgetPredicate(
      (widget) =>
          widget is Tooltip &&
          (widget.message?.contains('Nov 9, 2026') ?? false),
    );
    await tester.tap(bar);
    await tester.pumpAndSettle();
    expect(find.textContaining(r'Total: $9.90'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await pumpTestApp(
      tester,
      Scaffold(body: AdminIncomeChart(income: _income(empty: true))),
    );
    await tester.pumpAndSettle();
    expect(find.text('No income recorded in the last 7 days.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'tier styles stay distinct and property posts have a separate icon',
    (tester) async {
      await pumpTestApp(
        tester,
        const Scaffold(
          body: Row(
            children: [
              AdminRecordIcon(
                record: AdminRecord({
                  'purpose': 'SUBSCRIPTION',
                  'subscriptionTier': 'silver',
                }),
              ),
              AdminRecordIcon(
                record: AdminRecord({
                  'purpose': 'SUBSCRIPTION',
                  'subscriptionTier': 'gold',
                }),
              ),
              AdminRecordIcon(
                record: AdminRecord({
                  'purpose': 'SUBSCRIPTION',
                  'subscriptionTier': 'diamond',
                }),
              ),
              AdminRecordIcon(
                record: AdminRecord({
                  'purpose': 'LISTING_PUBLISH',
                  'propertyId': 'p1',
                }),
              ),
            ],
          ),
        ),
      );
      expect(find.byIcon(LucideIcons.award), findsNWidgets(2));
      final medals = tester
          .widgetList<Icon>(find.byIcon(LucideIcons.award))
          .toList();
      expect(medals[0].color, isNot(medals[1].color));
      expect(find.byIcon(LucideIcons.gem), findsOneWidget);
      expect(find.byIcon(LucideIcons.filePlus2), findsOneWidget);
      expect(find.byTooltip('One-time property post'), findsOneWidget);
      expect(find.byTooltip('Gold subscription'), findsOneWidget);
    },
  );

  for (final (label, purpose) in [
    ('Tier subscriptions', 'SUBSCRIPTION'),
    ('One-time property posts', 'LISTING_PUBLISH'),
  ]) {
    testWidgets(
      '$label opens payments with its purpose and preserves it during search and paging',
      (tester) async {
        final queries = <Map<String, dynamic>>[];
        final server = StubServer((request) {
          queries.add(Map.of(request.queryParameters));
          return (
            200,
            jsonEncode({
              'items': [
                {
                  'id': '${request.queryParameters['offset']}',
                  'purpose': purpose,
                },
              ],
              'nextOffset': request.queryParameters['offset'] == 0 ? 50 : null,
            }),
          );
        });
        await pumpTestApp(
          tester,
          Scaffold(body: AdminIncomeChart(income: _income())),
          overrides: [apiClientProvider.overrideWithValue(server.dio)],
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(queries.last, {
          'section': 'successful-payments',
          'offset': 0,
          'purpose': purpose,
        });
        await tester.enterText(find.byType(TextField), 'match');
        await tester.pumpAndSettle(const Duration(milliseconds: 400));
        expect(queries.last['purpose'], purpose);
        expect(queries.last['q'], 'match');
        await tester.tap(find.text('Load more'));
        await tester.pumpAndSettle();
        expect(queries.last, {
          'section': 'successful-payments',
          'offset': 50,
          'q': 'match',
          'purpose': purpose,
        });
        expect(tester.takeException(), isNull);
      },
    );
  }
}
