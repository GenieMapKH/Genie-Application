import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/admin/presentation/admin_deployments_panel.dart';
import 'package:tilomnov/features/admin/presentation/admin_operations_provider.dart';
import 'package:tilomnov/features/admin/presentation/admin_rotation_panel.dart';
import 'package:tilomnov/features/admin/presentation/admin_sentry_panel.dart';
import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';
import '../../support/test_app.dart';

const _latest = '00000000-0000-4000-8000-000000000001';
const _previous = '00000000-0000-4000-8000-000000000002';
Map<String, dynamic> _logPage(List<String> ids, {String? cursor}) => {
  'status': 'ok',
  'checkedAt': '2026-01-02T00:00:00Z',
  'environment': 'production',
  'nextCursor': cursor,
  'entries': [
    for (final id in ids)
      {
        'id': id,
        'timestamp': '2026-01-01T00:00:00Z',
        'project': 'api',
        'level': 'error',
        'message': 'Event $id',
      },
  ],
};

void main() {
  testWidgets(
    'rotation dates are independent of workflow status and force rotation requires confirmation without a reason field',
    (tester) async {
      var queued = false;
      final server = StubServer((request) {
        if (request.path.endsWith('/rotations')) {
          return (
            200,
            jsonEncode({
              'status': 'ok',
              'environment': 'prod',
              'checkedAt': '2026-01-02T00:00:00Z',
              'credentials': [
                {
                  'name': 'Users database',
                  'status': 'recorded',
                  'lastRotatedAt': '2026-01-01T00:00:00Z',
                },
                {
                  'name': 'Chat database',
                  'status': 'never_recorded',
                  'lastRotatedAt': null,
                },
              ],
            }),
          );
        }
        if (request.method == 'POST') {
          queued = true;
          return (201, '{"status":"accepted"}');
        }
        return (200, jsonEncode({'status': 'ok', 'runs': [], 'busy': queued}));
      });
      await pumpTestApp(
        tester,
        const Scaffold(
          body: SingleChildScrollView(child: AdminRotationPanel()),
        ),
        overrides: [apiClientProvider.overrideWithValue(server.dio)],
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Last rotated'), findsOneWidget);
      expect(find.text('No successful rotation recorded'), findsOneWidget);
      await tester.ensureVisible(find.text('Force rotate all'));
      await tester.tap(find.text('Force rotate all'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(server.requests.where((r) => r.method == 'POST'), isEmpty);
      await tester.tap(find.text('Force rotate all'));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNothing);
      await tester.tap(
        find.widgetWithText(FilledButton, 'Force rotate all').last,
      );
      await tester.pumpAndSettle();
      expect(server.requests.where((r) => r.method == 'POST').single.body, {
        'reason': 'Admin requested force rotation',
      });
      expect(
        find.text('Rotation is queued or running. Refresh to check progress.'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    },
  );

  test(
    'log pagination deduplicates entries and a failed refresh preserves the last successful page',
    () async {
      var fail = false;
      final cursors = <String?>[];
      final server = StubServer((request) {
        cursors.add(request.queryParameters['cursor'] as String?);
        if (fail) return (503, '{}');
        return (
          200,
          jsonEncode(
            request.queryParameters['cursor'] == 'older'
                ? _logPage(['a', 'b'])
                : _logPage(['a'], cursor: 'older'),
          ),
        );
      });
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(server.dio)],
      );
      final provider = adminLogsProvider('logs');
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(() {
        subscription.close();
        container.dispose();
      });
      await container.read(provider.future);
      await container.read(provider.notifier).refresh(older: true);
      expect(cursors, [null, 'older']);
      expect(container.read(provider).requireValue.entries.map((r) => r.id), [
        'a',
        'b',
      ]);
      fail = true;
      await container.read(provider.notifier).refresh();
      expect(container.read(provider).requireValue.refreshFailed, isTrue);
      expect(container.read(provider).requireValue.entries, hasLength(2));
      fail = false;
      await container.read(provider.notifier).refresh();
      expect(container.read(provider).requireValue.entries, hasLength(1));
      expect(container.read(provider).requireValue.refreshFailed, isFalse);
    },
  );

  testWidgets(
    'live feed polls, pauses, loads older events and switches datasets',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final datasets = <String>[];
      final server = StubServer((request) {
        datasets.add(request.queryParameters['dataset'] as String);
        return (
          200,
          jsonEncode(
            request.queryParameters['cursor'] == 'older'
                ? _logPage(['old'])
                : _logPage(['new'], cursor: 'older'),
          ),
        );
      });
      await pumpTestApp(
        tester,
        const Scaffold(body: SingleChildScrollView(child: AdminSentryPanel())),
        overrides: [apiClientProvider.overrideWithValue(server.dio)],
      );
      await tester.pumpAndSettle();
      expect(find.text('Event new'), findsOneWidget);
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      expect(server.requests.length, 2);
      await tester.tap(find.text('Pause live'));
      await tester.pump(const Duration(seconds: 20));
      expect(server.requests.length, 2);
      await tester.ensureVisible(find.text('Load older events'));
      await tester.tap(find.text('Load older events'));
      await tester.pumpAndSettle();
      expect(find.text('Event old'), findsOneWidget);
      await tester.ensureVisible(find.text('Logs'));
      await tester.tap(find.text('Logs'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Errors').last);
      await tester.pumpAndSettle();
      expect(datasets.last, 'errors');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('scrolling the feed pauses updates so entries remain readable', (
    tester,
  ) async {
    final server = StubServer(
      (_) => (200, jsonEncode(_logPage(List.generate(30, (i) => '$i')))),
    );
    await pumpTestApp(
      tester,
      const Scaffold(body: SingleChildScrollView(child: AdminSentryPanel())),
      overrides: [apiClientProvider.overrideWithValue(server.dio)],
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(find.text('Resume live'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'rollback reviews the target and sends its latest-deployment guard after confirmation',
    (tester) async {
      final server = StubServer(
        (request) => request.method == 'POST'
            ? (201, '{"status":"accepted"}')
            : (
                200,
                jsonEncode({
                  'status': 'ok',
                  'services': [
                    {
                      'name': 'user',
                      'latest': {
                        'id': _latest,
                        'status': 'CRASHED',
                        'createdAt': '2026-01-02T00:00:00Z',
                        'commit': 'new-commit',
                      },
                      'previous': {
                        'id': _previous,
                        'status': 'REMOVED',
                        'createdAt': '2026-01-01T00:00:00Z',
                        'commit': 'old-commit',
                      },
                    },
                  ],
                }),
              ),
      );
      await pumpTestApp(
        tester,
        const Scaffold(
          body: SingleChildScrollView(child: AdminDeploymentsPanel()),
        ),
        overrides: [apiClientProvider.overrideWithValue(server.dio)],
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Roll back user'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Restore user to old-commit'), findsOneWidget);
      expect(server.requests.where((r) => r.method == 'POST'), isEmpty);
      await tester.enterText(find.byType(TextFormField), 'Release crashes');
      await tester.tap(find.widgetWithText(FilledButton, 'Roll back user'));
      await tester.pumpAndSettle();
      final mutation = server.requests.where((r) => r.method == 'POST').single;
      expect(mutation.path, '/admin/operations/deployments/user/rollback');
      expect(mutation.body, {
        'reason': 'Release crashes',
        'deploymentId': _previous,
        'expectedLatestId': _latest,
      });
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    },
  );
}
