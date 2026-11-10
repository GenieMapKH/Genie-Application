import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/features/admin/presentation/admin_property_actions.dart';
import 'package:tilomnov/features/home/presentation/providers/map_properties_provider.dart';
import 'package:tilomnov/features/home/presentation/providers/property_carousel_provider.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/admin/presentation/admin_reports_page.dart';
import 'package:tilomnov/features/admin/presentation/admin_property_card.dart';
import 'package:tilomnov/features/admin/presentation/admin_moderation_dialog.dart';
import 'package:tilomnov/features/admin/presentation/admin_account_actions.dart';
import 'package:tilomnov/features/property/data/repositories/property_repository.dart';
import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';
import '../../support/test_app.dart';

void main() {
  testWidgets(
    'removing a map listing confirms the reason and clears its selected card',
    (tester) async {
      final property = PropertyModel(
        id: 'p-1',
        title: 'Map listing',
        price: '100000',
        propertyType: 'Land',
        status: 'Active',
        createdAt: DateTime(2026),
      );
      final server = StubServer.always(204, '');
      var changed = false;
      await pumpTestApp(
        tester,
        Scaffold(
          body: AdminPropertyActions(
            property: property,
            onChanged: () => changed = true,
          ),
        ),
        overrides: [
          apiClientProvider.overrideWithValue(server.dio),
          mapPropertiesProvider.overrideWithValue(const MapProperties()),
        ],
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(AdminPropertyActions)),
      );
      container.read(propertyCarouselProvider.notifier).select(property);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Remove post'));
      await tester.pumpAndSettle();
      expect(server.requests, isEmpty);
      await tester.enterText(find.byType(TextFormField), 'Misleading listing');
      await tester.tap(find.widgetWithText(FilledButton, 'Remove post'));
      await tester.pumpAndSettle();
      expect(server.requests.single.path, '/admin/properties/p-1/remove');
      expect(server.requests.single.body, {'reason': 'Misleading listing'});
      expect(container.read(propertyCarouselProvider).isVisible, isFalse);
      expect(changed, isTrue);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'administrator property reads and edits use protected routes and never fall back on denial',
    () async {
      final server = StubServer(
        (request) => request.method == 'GET'
            ? (403, '{}')
            : (
                200,
                '{"id":"p1","title":"Edited","price":"100","propertyType":"House","status":"Active","createdAt":"2026-11-09T00:00:00Z","images":[]}',
              ),
      );
      final repository = PropertyRepository(server.dio, admin: true);
      await expectLater(
        repository.fetchPropertyDetail('p1'),
        throwsA(anything),
      );
      expect(server.requests.map((request) => request.path), [
        '/admin/properties/p1',
      ]);
      await repository.update('p1', {'title': 'Edited'});
      await repository.removeImages('p1', ['owned-photo']);
      await repository.updateBoundary('p1', [
        {'lat': 11.5, 'lng': 104.8},
      ]);
      expect(server.requests.map((request) => request.path).toList(), [
        '/admin/properties/p1',
        '/admin/properties/p1',
        '/admin/properties/p1/images/remove',
        '/admin/properties/p1/boundary',
      ]);
    },
  );

  testWidgets(
    'account ban sends its reason only after administrator confirmation',
    (tester) async {
      const id = '00000000-0000-4000-8000-000000000001';
      final server = StubServer.always(204, '');
      await pumpTestApp(
        tester,
        const Scaffold(body: AdminAccountActions(userId: id)),
        overrides: [apiClientProvider.overrideWithValue(server.dio)],
      );
      await tester.tap(find.byTooltip('Account actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ban account'));
      await tester.pumpAndSettle();
      expect(server.requests, isEmpty);
      await tester.enterText(
        find.byType(TextFormField),
        'Repeated fraudulent posts',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Ban account'));
      await tester.pumpAndSettle();
      expect(server.requests.single.path, '/admin/users/$id/ban');
      expect(server.requests.single.body, {
        'reason': 'Repeated fraudulent posts',
      });
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'reports show one property card with count then reporter identities and people count',
    (tester) async {
      final server = StubServer((request) {
        if (request.path.endsWith('/property/p1')) {
          return (
            200,
            jsonEncode({
              'items': [
                {
                  'id': 'r1',
                  'reason': 'Scam',
                  'details': 'Misleading photos',
                  'reporter': {'id': 'u1', 'name': 'Dara', 'username': 'dara'},
                },
              ],
              'nextOffset': null,
              'reportCount': 3,
              'reporterCount': 3,
            }),
          );
        }
        return (
          200,
          jsonEncode({
            'items': [
              {
                'targetType': 'property',
                'targetId': 'p1',
                'reportCount': 3,
                'property': {
                  'id': 'p1',
                  'title': 'Reported house',
                  'createdAt': '2026-11-01T00:00:00Z',
                  'price': 4000,
                  'status': 'Active',
                  'images': [],
                },
              },
            ],
            'nextOffset': null,
          }),
        );
      });
      await pumpTestApp(
        tester,
        const AdminReportsPage(),
        overrides: [apiClientProvider.overrideWithValue(server.dio)],
      );
      await tester.pumpAndSettle();
      expect(find.byType(AdminPropertyCard), findsOneWidget);
      expect(find.text('3 reports'), findsOneWidget);
      await tester.ensureVisible(find.text('Reported house'));
      await tester.tap(find.text('Reported house'));
      await tester.pumpAndSettle();
      expect(find.text('3 reports from 3 people'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Scam'),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Scam'), findsOneWidget);
      expect(find.text('dara'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'permanent account deletion requires a reason and typed confirmation; cancel does nothing',
    (tester) async {
      String? result;
      await pumpTestApp(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await confirmModeration(
                  context,
                  title: 'Delete account',
                  message: 'Permanent deletion',
                  permanent: true,
                );
              },
              child: const Text('Open confirmation'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open confirmation'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete account'));
      await tester.pumpAndSettle();
      expect(find.text('Type DELETE to continue'), findsOneWidget);
      expect(result, isNull);
      await tester.enterText(
        find.byType(TextFormField).first,
        'Repeated scam posts',
      );
      await tester.enterText(find.byType(TextFormField).last, 'DELETE');
      await tester.tap(find.widgetWithText(FilledButton, 'Delete account'));
      await tester.pumpAndSettle();
      expect(result, 'Repeated scam posts');
      result = null;
      await tester.tap(find.text('Open confirmation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
