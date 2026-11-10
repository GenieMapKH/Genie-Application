import 'package:tilomnov/features/admin/presentation/admin_reports_page.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/admin/presentation/admin_dashboard_page.dart';
import 'package:tilomnov/features/admin/presentation/admin_metric_card.dart';
import 'package:tilomnov/features/admin/presentation/admin_records_page.dart';
import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';

import '../../support/test_app.dart';

final _overview = {
  'generatedAt': '2026-11-09T10:00:00Z',
  'users': {'total': 1234567, 'active': 1, 'newLast7Days': 1},
  'openReports': 1,
  'listings': {'total': 2, 'active': 1, 'newLast7Days': 1, 'leadsLast7Days': 1},
  'payments': {
    'activeSubscriptions': 2,
    'pendingTransactions': 1,
    'successfulTransactions7d': 1,
    'volumeUsd7d': 8.9,
    'simulated': true,
    'subscriptionsByTier': {'gold': 2},
    'income': {
      'timeZone': 'Asia/Phnom_Penh',
      'subscriptionUsd': 8.9,
      'listingUsd': 0,
      'days': [
        {'date': '2026-11-08', 'subscriptionUsd': 0, 'listingUsd': 0},
        {'date': '2026-11-09', 'subscriptionUsd': 8.9, 'listingUsd': 0},
      ],
    },
  },
};

final _health = {
  'checkedAt': '2026-11-09T10:00:00Z',
  'services': [
    {'name': 'Users', 'status': 'up', 'latencyMs': 15},
    {'name': 'Payments', 'status': 'down', 'latencyMs': 25, 'httpStatus': 503},
    {'name': 'API gateway', 'status': 'not_configured', 'latencyMs': null},
  ],
};

void main() {
  for (final theme in ['light', 'dark']) {
    for (final section in AdminSection.values) {
      testWidgets(
        '$theme ${section.name} header keeps its color while scrolling',
        (tester) async {
          tester.view.physicalSize = const Size(400, 400);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final server = StubServer(
            (request) => (
              200,
              jsonEncode(
                request.path.endsWith('/health') ? _health : _overview,
              ),
            ),
          );
          await pumpTestApp(
            tester,
            AdminDashboardPage(section: section),
            overrides: [apiClientProvider.overrideWithValue(server.dio)],
            savedSettings: {'settings.theme_mode': theme},
          );
          await tester.pumpAndSettle();
          final appBar = find.byType(AppBar);
          final material = find
              .descendant(of: appBar, matching: find.byType(Material))
              .first;
          final before = tester.widget<Material>(material);
          final surface = Theme.of(tester.element(appBar)).colorScheme.surface;
          expect(before.color, surface);
          await tester.drag(
            find.byKey(PageStorageKey('admin-${section.name}')),
            const Offset(0, -200),
          );
          await tester.pumpAndSettle();
          expect(
            tester
                .state<ScrollableState>(find.byType(Scrollable).first)
                .position
                .pixels,
            greaterThan(0),
          );
          final after = tester.widget<Material>(material);
          expect(after.color, surface);
          expect(after.elevation, before.elevation);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final width in [320.0, 768.0, 1440.0]) {
    testWidgets('dashboard fits $width width with large text and totals', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final overview = {
        ..._overview,
        'payments': {
          ..._overview['payments']! as Map<String, Object>,
          'volumeUsd7d': 1234567890.12,
        },
      };
      final server = StubServer(
        (request) => request.path.endsWith('/health')
            ? (200, jsonEncode(_health))
            : (200, jsonEncode(overview)),
      );
      for (final section in AdminSection.values) {
        await pumpTestApp(
          tester,
          MediaQuery(
            data: MediaQueryData(
              size: Size(width, 900),
              textScaler: const TextScaler.linear(1.5),
            ),
            child: AdminDashboardPage(key: ValueKey(section), section: section),
          ),
          overrides: [apiClientProvider.overrideWithValue(server.dio)],
          savedSettings: const {'settings.theme_mode': 'dark'},
        );
        await tester.pumpAndSettle();
        if (section == AdminSection.account ||
            section == AdminSection.activity) {
          final count = section == AdminSection.account ? 4 : 5;
          final cards = find.byType(AdminMetricCard);
          expect(cards, findsNWidgets(count));
          final size = tester.getSize(cards.first);
          for (var index = 1; index < count; index++) {
            expect(tester.getSize(cards.at(index)), size);
          }
        }
        if (section == AdminSection.financial) {
          await tester.ensureVisible(find.text('Diamond'));
          await tester.pumpAndSettle();
          expect(find.text('Gold'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets(
    'every metric and tier card opens its matching scrollable detail list',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final queries = <Map<String, dynamic>>[];
      final server = StubServer((request) {
        if (request.path.endsWith('/health')) return (200, jsonEncode(_health));
        if (request.path.endsWith('/moderation/reports')) {
          return (200, '{"items":[],"nextOffset":null}');
        }
        if (request.path.endsWith('/records')) {
          queries.add(request.queryParameters);
          return (200, '{"items":[],"nextOffset":null}');
        }
        return (200, jsonEncode(_overview));
      });
      await pumpTestApp(
        tester,
        const AdminDashboardPage(),
        overrides: [apiClientProvider.overrideWithValue(server.dio)],
      );
      await tester.pumpAndSettle();

      for (final entry in {
        'Active users': 'active-users',
        'Active listings': 'active-listings',
        'Open reports': 'reports',
        'Listing leads': 'leads',
        'All users': 'all-users',
        'All listings': 'all-listings',
        'Subscriptions': 'subscriptions',
        'New users': 'new-users',
        'New listings': 'new-listings',
        'Income - last 7 days': 'successful-payments',
        'Successful payments': 'successful-payments',
        'Pending payments': 'pending-payments',
      }.entries) {
        final section =
            [
              'active-users',
              'all-users',
              'subscriptions',
              'new-users',
            ].contains(entry.value)
            ? AdminSection.account
            : ['successful-payments', 'pending-payments'].contains(entry.value)
            ? AdminSection.financial
            : AdminSection.activity;
        await pumpTestApp(
          tester,
          AdminDashboardPage(key: ValueKey(section), section: section),
          overrides: [apiClientProvider.overrideWithValue(server.dio)],
        );
        await tester.pumpAndSettle();
        final card = find.text(entry.key);
        await tester.ensureVisible(card);
        await tester.pumpAndSettle();
        await tester.tap(card);
        await tester.pumpAndSettle();
        if (entry.value == 'reports') {
          expect(find.byType(AdminReportsPage), findsOneWidget);
          expect(server.requests.last.path, endsWith('/moderation/reports'));
          expect(find.text('No reports found'), findsOneWidget);
        } else {
          expect(find.byType(AdminRecordsPage), findsOneWidget);
          expect(queries.last['section'], entry.value);
          expect(find.text('No records found'), findsOneWidget);
        }
        expect(find.byType(ListView), findsOneWidget);
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
      }
      expect(find.textContaining('simulation mode'), findsNothing);
      expect(find.text('Simulated volume'), findsNothing);
      await tester.ensureVisible(find.text('Gold'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gold'));
      await tester.pumpAndSettle();
      expect(queries.last, {
        'section': 'subscriptions',
        'offset': 0,
        'tier': 'gold',
      });
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'account details expand, pages append without duplicates and failed pages can retry',
    (tester) async {
      var failNextPage = true;
      final offsets = <int>[];
      final user = {
        'id': 'u1',
        'username': 'sokha',
        'name': 'Sokha Chan',
        'email': 'sokha@example.com',
        'phone': '+85512345678',
        'emailVerified': true,
      };
      final server = StubServer((request) {
        final offset = request.queryParameters['offset'] as int;
        offsets.add(offset);
        if (offset == 0) {
          return (
            200,
            jsonEncode({
              'items': [user],
              'nextOffset': 50,
            }),
          );
        }
        if (failNextPage) return (503, '{}');
        return (
          200,
          jsonEncode({
            'items': [
              user,
              {'id': 'u2', 'username': 'dara'},
            ],
            'nextOffset': null,
          }),
        );
      });
      await pumpTestApp(
        tester,
        const AdminRecordsPage(section: 'active-users', title: 'Active users'),
        overrides: [apiClientProvider.overrideWithValue(server.dio)],
        savedSettings: const {'settings.theme_mode': 'dark'},
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('@sokha'));
      await tester.pumpAndSettle();
      expect(find.text('+85512345678'), findsOneWidget);
      expect(find.text('Email Verified'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Load more'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.text('Load more'));
      await tester.pumpAndSettle();
      expect(find.text('@sokha'), findsOneWidget);
      expect(find.text('Load more'), findsOneWidget);
      failNextPage = false;
      await tester.tap(find.text('Load more'));
      await tester.pumpAndSettle();
      expect(offsets, [0, 50, 50]);
      expect(find.text('@sokha'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('@dara'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('@dara'), findsOneWidget);
      expect(find.text('Load more'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'services load independently of metrics and distinguish service states',
    (tester) async {
      final server = StubServer(
        (request) => request.path.endsWith('/health')
            ? (200, jsonEncode(_health))
            : (503, '{}'),
      );
      await pumpTestApp(
        tester,
        const AdminDashboardPage(section: AdminSection.services),
        overrides: [apiClientProvider.overrideWithValue(server.dio)],
      );
      await tester.pumpAndSettle();
      expect(
        server.requests.any((request) => request.path.endsWith('/health')),
        isTrue,
      );
      expect(
        server.requests.any((request) => request.path == '/admin/dashboard'),
        isFalse,
      );
      expect(find.text('1 of 3 responding'), findsOneWidget);

      expect(find.text('Responding'), findsOneWidget);
      expect(find.text('Unhealthy response (HTTP 503)'), findsOneWidget);
      expect(find.text('Service address not configured'), findsOneWidget);
      expect(find.text('15 ms'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
