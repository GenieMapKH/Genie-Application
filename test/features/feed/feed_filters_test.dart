import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/feed/data/feed_filters.dart';
import 'package:tilomnov/features/feed/presentation/widgets/feed_filter_sheet.dart';

import '../../support/test_app.dart';

void main() {
  test(
    'date filters include the whole last local day and preserve zero prices',
    () {
      final filters = FeedFilters(
        sort: FeedSort.priceLow,
        propertyType: 'House',
        minPrice: 0,
        maxPrice: 200,
        fromDate: DateTime(2026, 11, 1),
        toDate: DateTime(2026, 11, 8),
      );
      expect(filters.toQuery(), {
        'sort': 'priceLow',
        'propertyType': 'House',
        'minPrice': 0.0,
        'maxPrice': 200.0,
        'since': DateTime(2026, 11, 1).toUtc().toIso8601String(),
        'until': DateTime(2026, 11, 9).toUtc().toIso8601String(),
      });
      expect(filters.activeCount, 4);
      expect(const FeedFilters().isDefault, isTrue);
      expect(
        const FeedFilters(minPrice: 200, maxPrice: 100).priceRangeReversed,
        isTrue,
      );
      expect(const FeedFilters(maxPrice: double.infinity).pricesValid, isFalse);
      expect(const FeedFilters(minPrice: -1).pricesValid, isFalse);
      expect(const FeedFilters(maxPrice: 10000000000).pricesValid, isFalse);
    },
  );

  testWidgets(
    'an invalid price range blocks Apply and Reset clears the fields',
    (tester) async {
      await pumpTestApp(
        tester,
        const Scaffold(
          body: FeedFilterSheet(
            initial: FeedFilters(minPrice: 200, maxPrice: 100),
          ),
        ),
      );
      final apply = find.widgetWithText(FilledButton, 'See results');
      final reset = find.widgetWithText(TextButton, 'Reset');
      expect(tester.getCenter(reset).dy, tester.getCenter(apply).dy);
      expect(tester.getRect(reset).right, lessThan(tester.getRect(apply).left));
      expect(tester.widget<FilledButton>(apply).onPressed, isNull);
      expect(find.text('The minimum is above the maximum'), findsOneWidget);
      await tester.tap(find.text('Reset'));
      await tester.pump();
      expect(tester.widget<FilledButton>(apply).onPressed, isNotNull);
      final fields = tester.widgetList<TextField>(find.byType(TextField));
      expect(fields.every((field) => field.controller!.text.isEmpty), isTrue);
    },
  );

  testWidgets('selecting filters keeps chip sizes and wrapping unchanged', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpTestApp(
      tester,
      const Scaffold(body: FeedFilterSheet(initial: FeedFilters())),
    );

    final sort = find.widgetWithText(ChoiceChip, 'Top (most saved)');
    final sortBefore = tester.getRect(sort);
    await tester.tap(sort);
    await tester.pumpAndSettle();
    expect(tester.widget<ChoiceChip>(sort).selected, isTrue);
    expect(tester.getRect(sort), sortBefore);

    final anyTime = find.widgetWithText(ChoiceChip, 'Any time');
    final dateBefore = tester.getRect(anyTime);
    await tester.tap(find.text('Last 7 days'));
    await tester.pumpAndSettle();
    expect(tester.widget<ChoiceChip>(anyTime).selected, isFalse);
    expect(tester.getRect(anyTime), dateBefore);

    await tester.ensureVisible(find.text('Warehouse'));
    await tester.pumpAndSettle();
    final types = find.byType(FilterChip);
    final before = [
      for (final chip in types.evaluate())
        tester.getRect(find.byWidget(chip.widget)),
    ];
    final business = find.widgetWithText(FilterChip, 'Business for Sale');
    await tester.tap(business);
    await tester.pumpAndSettle();
    expect(tester.widget<FilterChip>(business).selected, isTrue);
    expect([
      for (final chip in types.evaluate())
        tester.getRect(find.byWidget(chip.widget)),
    ], before);
    await tester.tap(business);
    await tester.pumpAndSettle();
    expect(tester.widget<FilterChip>(business).selected, isFalse);
    expect([
      for (final chip in types.evaluate())
        tester.getRect(find.byWidget(chip.widget)),
    ], before);
    expect(tester.takeException(), isNull);
  });

  for (final language in ['en', 'km']) {
    testWidgets(
      '$language filter sheet fits a small phone with keyboard and larger text',
      (tester) async {
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await pumpTestApp(
          tester,
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.6),
                viewInsets: const EdgeInsets.only(bottom: 260),
              ),
              child: const Scaffold(
                body: FeedFilterSheet(initial: FeedFilters()),
              ),
            ),
          ),
          savedSettings: {'settings.language': language},
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(ListView), const Offset(0, -1000));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
