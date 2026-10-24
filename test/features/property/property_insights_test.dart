import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/property/data/models/property_insights.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/data/repositories/property_repository.dart';
import 'package:genie/features/property/presentation/screens/property_insights_page.dart';
import 'package:genie/features/property/presentation/view_models/property_providers.dart';

import '../../support/test_app.dart';

/// 14 days from 11 to 24 October; [views] by day, oldest first.
String insightsJson({List<int>? views, int totalViews = 9}) {
  final perDay = views ?? List.filled(14, 0);
  return jsonEncode({
    'totals': {'views': totalViews, 'saves': 2, 'calls': 1, 'chats': 3},
    'days': [
      for (var i = 0; i < 14; i++)
        {
          'date': '2026-10-${(11 + i).toString().padLeft(2, '0')}',
          'views': perDay[i],
          'saves': i == 13 ? 2 : 0,
          'leads': i == 12 ? 4 : 0,
        },
    ],
  });
}

final _listing = PropertyModel(
  id: 'p-1',
  title: 'Villa near Riverside',
  price: '250000',
  propertyType: 'Villa',
  status: 'Active',
  createdAt: DateTime(2026),
);

void main() {
  test('reads totals and days, and sums this week against the one before', () {
    final insights = PropertyInsights.fromJson(
      jsonDecode(
            insightsJson(views: [1, 0, 0, 0, 0, 0, 2, 3, 0, 0, 0, 0, 0, 5]),
          )
          as Map<String, dynamic>,
    );

    expect(insights.views, 9);
    expect(insights.chats, 3);
    expect(insights.days, hasLength(14));
    expect(insights.days.last.date, DateTime(2026, 10, 24));
    expect(insights.weekOf(InsightMeasure.views), (thisWeek: 8, lastWeek: 3));
    expect(insights.weekOf(InsightMeasure.leads), (thisWeek: 4, lastWeek: 0));
    expect(insights.isEmpty, isFalse);
  });

  test('records a lead and reads insights from the listing', () async {
    final server = StubServer((request) {
      return request.path.endsWith('/insights')
          ? (200, insightsJson())
          : (204, '');
    });
    final repository = PropertyRepository(server.dio, storageDio: server.dio);

    await repository.recordLead('p-1', LeadChannel.call);
    final insights = await repository.fetchInsights('p-1');

    expect(server.requests.first.method, 'POST');
    expect(server.requests.first.path, '/properties/p-1/lead');
    expect(server.requests.first.body, {'channel': 'call'});
    expect(server.requests.last.path, '/properties/p-1/insights');
    expect(insights.saves, 2);
  });

  test('a lead that cannot be recorded does not fail the tap', () async {
    final repository = PropertyRepository(
      StubServer.always(500).dio,
      storageDio: StubServer.always(500).dio,
    );
    await expectLater(
      repository.recordLead('p-1', LeadChannel.chat),
      completes,
    );
  });

  group('the page', () {
    Future<StubServer> open(WidgetTester tester, {int status = 200}) async {
      final server = StubServer(
        (_) => (status, insightsJson(views: [...List.filled(13, 0), 3])),
      );
      await pumpTestApp(
        tester,
        PropertyInsightsPage(property: _listing),
        overrides: [
          propertyRepositoryProvider.overrideWithValue(
            PropertyRepository(server.dio, storageDio: server.dio),
          ),
        ],
      );
      await tester.pumpAndSettle();
      return server;
    }

    testWidgets('shows the totals and the newest day of viewers', (
      tester,
    ) async {
      await open(tester);

      expect(find.text('Villa near Riverside'), findsOneWidget);
      expect(find.text('People viewed'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(find.text('Started a chat'), findsOneWidget);
      expect(find.text('Oct 24 · 3 new viewers'), findsOneWidget);
      expect(
        find.text('This week: 3 new viewers. The week before: 0.'),
        findsOneWidget,
      );
    });

    testWidgets('switches to leads, and names the day tapped', (tester) async {
      await open(tester);

      await tester.tap(find.text('Leads'));
      await tester.pumpAndSettle();
      expect(find.text('Oct 24 · 0 new leads'), findsOneWidget);

      // The 13th of 14 bars: the 23rd, with its 4 leads.
      final chart = tester.getRect(find.byType(CustomPaint).last);
      await tester.tapAt(
        Offset(chart.left + chart.width * 12.5 / 14, chart.center.dy),
      );
      await tester.pump();
      expect(find.text('Oct 23 · 4 new leads'), findsOneWidget);
    });

    testWidgets('a failure says so and tries again', (tester) async {
      final server = await open(tester, status: 500);

      expect(
        find.text("Couldn't load the insights. Check your connection."),
        findsOneWidget,
      );
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(server.requests.length, greaterThan(1));
    });
  });
}
