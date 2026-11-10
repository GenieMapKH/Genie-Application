import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/features/advertisements/data/advertisement.dart';
import 'package:tilomnov/core/media/image_compressor.dart';
import 'package:tilomnov/features/advertisements/data/advertisements_repository.dart';
import 'package:tilomnov/features/advertisements/presentation/advertisements_provider.dart';
import 'package:tilomnov/features/admin/presentation/admin_advertisements_page.dart';
import '../../support/test_app.dart';

void main() {
  testWidgets(
    'open sessions pick up advertisement additions and removals on the next refresh',
    (tester) async {
      final repository = _AdsRepository();
      await pumpTestApp(
        tester,
        Consumer(
          builder: (_, ref, _) => Text(
            'Ads: ${ref.watch(activeAdvertisementsProvider).valueOrNull?.length ?? 0}',
          ),
        ),
        overrides: [
          advertisementsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.text('Ads: 0'), findsOneWidget);
      repository.ads = const [Advertisement(id: 'ad', imageUrl: 'photo')];
      await tester.pump(const Duration(minutes: 1));
      await tester.pumpAndSettle();
      expect(find.text('Ads: 1'), findsOneWidget);
      repository.ads = [];
      await tester.pump(const Duration(minutes: 1));
      await tester.pumpAndSettle();
      expect(find.text('Ads: 0'), findsOneWidget);
      expect(repository.calls, 3);
    },
  );

  testWidgets(
    'administrator removal requires confirmation and reloads the empty manager',
    (tester) async {
      var removed = false;
      final server = StubServer((request) {
        if (request.method == 'DELETE') {
          removed = true;
          return (204, '');
        }
        return removed
            ? (200, '[]')
            : (200, '[{"id":"ad","imageUrl":"https://images.test/ad.jpg"}]');
      });
      await pumpTestApp(
        tester,
        const AdminAdvertisementsPage(),
        overrides: [
          advertisementsRepositoryProvider.overrideWithValue(
            AdvertisementsRepository(server.dio),
          ),
          activeAdvertisementsProvider.overrideWith((_) async => []),
        ],
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Remove photo'));
      await tester.tap(find.text('Remove photo'));
      await tester.pumpAndSettle();
      expect(removed, isFalse);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(removed, isFalse);
      await tester.tap(find.text('Remove photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
      await tester.pumpAndSettle();
      expect(removed, isTrue);
      expect(find.text('No ads yet'), findsOneWidget);
      expect(
        server.requests
            .where((request) => request.method == 'DELETE')
            .single
            .path,
        '/admin/ads/ad',
      );
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'photo upload uses its signed storage permission without forwarding the admin token',
    () async {
      final api = StubServer(
        (request) => request.path.endsWith('/uploads')
            ? (
                200,
                '{"path":"owner/photo","uploadUrl":"https://storage.test/upload"}',
              )
            : (200, '{}'),
      );
      final storage = StubServer.always(200);
      final apiDio = api.dio
        ..options.headers['authorization'] = 'Bearer owner-session';
      final storageDio = storage.dio;
      Map<String, dynamic>? uploadHeaders;
      storageDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            uploadHeaders = request.headers;
            handler.next(request);
          },
        ),
      );
      final repository = AdvertisementsRepository(
        apiDio,
        storageDio: storageDio,
      );
      await repository.upload(
        PreparedImage(
          bytes: Uint8List.fromList([1, 2, 3]),
          name: 'ad.jpg',
          mimeType: 'image/jpeg',
        ),
      );
      expect(api.requests.map((request) => request.path), [
        '/admin/ads/uploads',
        '/admin/ads',
      ]);
      expect(api.requests.last.body, {'path': 'owner/photo'});
      expect(storage.requests.single.method, 'PUT');
      expect(uploadHeaders, isNot(contains('authorization')));
      expect(uploadHeaders?['content-type'], 'image/jpeg');
    },
  );

  testWidgets(
    'no configured ads gives the administrator an empty manager and enabled upload action',
    (tester) async {
      final server = StubServer.always(200, '[]');
      await pumpTestApp(
        tester,
        const AdminAdvertisementsPage(),
        overrides: [
          advertisementsRepositoryProvider.overrideWithValue(
            AdvertisementsRepository(server.dio),
          ),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.text('No ads yet'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Add photos'), findsOneWidget);
      expect(server.requests.single.path, '/admin/ads');
      expect(tester.takeException(), isNull);
    },
  );
}

class _AdsRepository extends AdvertisementsRepository {
  List<Advertisement> ads = [];
  int calls = 0;
  _AdsRepository() : super(Dio());
  @override
  Future<List<Advertisement>> load({bool admin = false}) async {
    calls++;
    return [...ads];
  }
}
