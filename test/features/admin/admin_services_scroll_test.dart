import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/admin/data/admin_rotation_status.dart';
import 'package:tilomnov/features/admin/presentation/admin_dashboard_page.dart';
import 'package:tilomnov/features/admin/presentation/admin_dashboard_provider.dart';
import 'package:tilomnov/features/admin/presentation/admin_sentry_panel.dart';
import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';
import '../../support/test_app.dart';

const _services = [
  'Authentication',
  'Users',
  'Listings',
  'Chat',
  'Payments',
  'Notifications',
  'API gateway',
];
final _rotation = AdminRotationStatus.fromJson({
  'status': 'ok',
  'checkedAt': '2026-11-10T00:00:00Z',
  'environment': 'prod',
  'credentials': [
    for (final service in _services)
      {
        'name': '$service database',
        'status': 'recorded',
        'lastRotatedAt': '2026-11-09T00:00:00Z',
      },
  ],
});

void main() {
  testWidgets(
    'service panels stay mounted and keep scroll position during polls and refreshes',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var rotationLoads = 0;
      var pending = Completer<AdminRotationStatus>();
      final server = StubServer((request) {
        if (request.path.endsWith('/health')) {
          return (
            200,
            jsonEncode({
              'checkedAt': '2026-11-10T00:00:00Z',
              'services': [
                for (final name in _services)
                  {'name': name, 'status': 'up', 'latencyMs': 12},
              ],
            }),
          );
        }
        if (request.path.endsWith('/rotation-job')) {
          return (200, '{"status":"ok","busy":false,"runs":[]}');
        }
        if (request.path.endsWith('/deployments')) {
          return (
            200,
            jsonEncode({
              'status': 'ok',
              'services': [
                for (final name in _services)
                  {'name': name, 'latest': null, 'previous': null},
              ],
            }),
          );
        }
        return (
          200,
          jsonEncode({
            'status': 'ok',
            'environment': 'production',
            'checkedAt': '2026-11-10T00:00:00Z',
            'entries': [],
            'nextCursor': null,
          }),
        );
      });
      await pumpTestApp(
        tester,
        const AdminDashboardPage(section: AdminSection.services),
        overrides: [
          apiClientProvider.overrideWithValue(server.dio),
          adminRotationProvider.overrideWith((ref) {
            rotationLoads++;
            return rotationLoads == 1
                ? Future.value(_rotation)
                : pending.future;
          }),
        ],
      );
      await tester.pumpAndSettle();
      final scroll = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      scroll.jumpTo(scroll.maxScrollExtent);
      await tester.pumpAndSettle();
      final offset = scroll.pixels;
      expect(offset, greaterThan(0));
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      expect(scroll.pixels, closeTo(offset, .1));
      expect(
        server.requests.where((r) => r.path.endsWith('/logs')),
        hasLength(2),
      );
      expect(
        server.requests.where((r) => r.path.endsWith('/health')),
        hasLength(1),
      );
      expect(rotationLoads, 1);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(AdminDashboardPage)),
      );
      container.invalidate(adminRotationProvider);
      await tester.pump();
      expect(find.textContaining('Last rotated'), findsNWidgets(7));
      expect(scroll.pixels, closeTo(offset, .1));
      pending.complete(_rotation);
      await tester.pumpAndSettle();
      expect(scroll.pixels, closeTo(offset, .1));

      pending = Completer<AdminRotationStatus>();
      container.invalidate(adminRotationProvider);
      await tester.pump();
      pending.future.ignore();
      pending.completeError(Exception('Offline'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Last rotated'), findsNWidgets(7));
      expect(
        find.text('Refresh failed. Showing the last successful check.'),
        findsOneWidget,
      );
      expect(scroll.pixels, closeTo(offset, .1));
      scroll.jumpTo(0);
      await tester.pumpAndSettle();
      expect(
        server.requests.where((r) => r.path.endsWith('/health')),
        hasLength(1),
      );
      expect(rotationLoads, 3);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Sentry starts on errors and dataset changes keep a stable card height',
    (tester) async {
      final datasets = <String>[];
      final server = StubServer((request) {
        final dataset = request.queryParameters['dataset'] as String;
        datasets.add(dataset);
        return (
          200,
          jsonEncode({
            'status': 'ok',
            'environment': 'production',
            'checkedAt': '2026-11-10T00:00:00Z',
            'nextCursor': null,
            'entries': dataset == 'logs'
                ? []
                : [
                    {
                      'id': 'one',
                      'timestamp': '2026-11-10T00:00:00Z',
                      'project': 'user',
                      'level': 'error',
                      'message': 'Real error',
                    },
                  ],
          }),
        );
      });
      await pumpTestApp(
        tester,
        const Scaffold(body: SingleChildScrollView(child: AdminSentryPanel())),
        overrides: [apiClientProvider.overrideWithValue(server.dio)],
      );
      await tester.pumpAndSettle();
      expect(datasets, ['errors']);
      expect(find.text('Real error'), findsOneWidget);
      final height = tester.getSize(find.byType(AdminSentryPanel)).height;
      await tester.tap(find.text('Logs'));
      await tester.pumpAndSettle();
      expect(
        find.text('No logs received in the last 24 hours'),
        findsOneWidget,
      );
      expect(tester.getSize(find.byType(AdminSentryPanel)).height, height);
      expect(find.textContaining('services are healthy'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
