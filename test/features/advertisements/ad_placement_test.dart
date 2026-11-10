import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/advertisements/data/advertisement.dart';
import 'package:tilomnov/features/advertisements/presentation/advertised_sliver_grid.dart';
import 'package:tilomnov/features/advertisements/presentation/advertisement_banner.dart';
import 'package:tilomnov/features/advertisements/presentation/advertisements_provider.dart';
import 'package:tilomnov/features/closest_listings/presentation/view_models/closest_listings_provider.dart';
import 'package:tilomnov/features/closest_listings/presentation/widgets/closest_listings_body.dart';
import 'package:tilomnov/features/property/presentation/screens/saved_properties_page.dart';
import 'package:tilomnov/shared/utils/paged_list.dart';
import '../../support/test_app.dart';

const _ads = [
  Advertisement(id: 'a1', imageUrl: 'https://images.test/ad1.jpg'),
  Advertisement(id: 'a2', imageUrl: 'https://images.test/ad2.jpg'),
];
const _portrait = Advertisement(
  id: 'portrait',
  imageUrl: 'https://images.test/portrait.jpg',
  width: 800,
  height: 1600,
);

void main() {
  test(
    'stored image dimensions select portrait cards and keep old responses compatible',
    () {
      expect(
        Advertisement.fromJson({
          'id': 'a',
          'imageUrl': 'photo',
          'width': 800,
          'height': 1600,
        }).isPortrait,
        isTrue,
      );
      expect(
        Advertisement.fromJson({
          'id': 'a',
          'imageUrl': 'photo',
          'width': 1600,
          'height': 700,
        }).isPortrait,
        isFalse,
      );
      expect(
        Advertisement.fromJson({
          'id': 'a',
          'imageUrl': 'photo',
          'width': 800,
          'height': 800,
        }).isPortrait,
        isFalse,
      );
      expect(
        Advertisement.fromJson({'id': 'a', 'imageUrl': 'photo'}).isPortrait,
        isFalse,
      );
    },
  );

  for (final portrait in [false, true]) {
    testWidgets(
      'standalone ${portrait ? 'portrait' : 'landscape'} ad uses a standard frame without cropping',
      (tester) async {
        tester.view.physicalSize = const Size(400, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await pumpTestApp(
          tester,
          Scaffold(
            body: ListView(
              children: [
                AdvertisementBanner(
                  advertisement: portrait ? _portrait : _ads.first,
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        final frame = find.descendant(
          of: find.byType(AdvertisementBanner),
          matching: find.byType(ClipRRect),
        );
        final size = tester.getSize(frame);
        expect(size.width, 400);
        expect(size.width / size.height, closeTo(16 / 7, .001));
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final mixed in [false, true]) {
    for (final count in [0, 1, 4, 9, 12]) {
      testWidgets(
        '${mixed ? 'mixed' : 'portrait'} ads preserve $count tablet grid listings and match card sizing',
        (tester) async {
          tester.view.physicalSize = const Size(800, 1600);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await pumpTestApp(
            tester,
            Scaffold(
              body: CustomScrollView(
                slivers: [
                  AdvertisedSliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisExtent: 100,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: count,
                    itemBuilder: (_, index) =>
                        SizedBox.expand(child: Text('Listing $index')),
                  ),
                ],
              ),
            ),
            overrides: [
              activeAdvertisementsProvider.overrideWith(
                (_) async => [_portrait, if (mixed) _ads.first],
              ),
            ],
          );
          await tester.pumpAndSettle();
          for (var index = 0; index < count; index++) {
            expect(find.text('Listing $index'), findsOneWidget);
          }
          final cards = find.byWidgetPredicate(
            (widget) =>
                widget is AdvertisementBanner &&
                widget.advertisement.isPortrait,
          );
          expect(cards, findsWidgets);
          expect(
            tester.getSize(cards.first),
            count == 0 ? const Size(800, 350) : const Size(400, 100),
          );
          if (!mixed && count >= 9) {
            expect(
              tester.getRect(cards.at(1)).top -
                  tester.getRect(find.text('Listing 2')).bottom,
              12,
            );
          }
          if (count > 0) {
            expect(
              tester.getRect(cards.first).top,
              tester.getRect(find.text('Listing 0')).top,
            );
            expect(
              tester.getRect(cards.first).right,
              lessThanOrEqualTo(tester.getRect(find.text('Listing 0')).left),
            );
          }
          if (mixed && count >= 9) {
            final wide = find.byWidgetPredicate(
              (widget) =>
                  widget is AdvertisementBanner &&
                  !widget.advertisement.isPortrait,
            );
            expect(wide, findsWidgets);
            expect(tester.getSize(wide.first).width, 800);
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final (size, columns) in [
    (const Size(400, 2400), 1),
    (const Size(400, 2400), 2),
    (const Size(800, 2400), 1),
    (const Size(800, 400), 2),
  ]) {
    for (final count in [0, 1, if (size.height > 400) 9]) {
      testWidgets(
        'portrait ads stay horizontal at $size with $columns columns and $count listings',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await pumpTestApp(
            tester,
            Scaffold(
              body: CustomScrollView(
                slivers: [
                  AdvertisedSliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisExtent: 40,
                    ),
                    itemCount: count,
                    itemBuilder: (_, index) => Text('Listing $index'),
                  ),
                ],
              ),
            ),
            overrides: [
              activeAdvertisementsProvider.overrideWith(
                (_) async => [_portrait],
              ),
            ],
          );
          await tester.pumpAndSettle();
          final banners = find.byType(AdvertisementBanner);
          expect(banners, findsWidgets);
          for (final element in banners.evaluate()) {
            expect((element.widget as AdvertisementBanner).inGrid, isFalse);
            final bannerSize = tester.getSize(find.byWidget(element.widget));
            expect(bannerSize.width, size.width);
            expect(bannerSize.width / bannerSize.height, closeTo(16 / 7, .001));
          }
          for (var index = 0; index < count; index++) {
            expect(find.text('Listing $index'), findsOneWidget);
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final screen in ['Saved', 'Nearby']) {
    testWidgets('$screen shows ads when its listing list is empty', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        screen == 'Saved'
            ? const SavedPropertiesPage()
            : Scaffold(
                body: CustomScrollView(
                  slivers: [
                    ClosestListingsBody(
                      width: 400,
                      height: 800,
                      onOpen: (_) {},
                    ),
                  ],
                ),
              ),
        overrides: [
          signedInOverride(signedIn: false),
          closestListingsProvider.overrideWith(_EmptyClosestListings.new),
          activeAdvertisementsProvider.overrideWith((_) async => _ads),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.byType(AdvertisementBanner), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  test(
    'feed ad placement preserves listings and shows one banner for short lists',
    () {
      for (var count = 0; count < 50; count++) {
        final entries = [
          for (var index = 0; index < count + adSlotCount(count); index++)
            listingIndexAtAdSlot(index, count),
        ];
        expect(
          entries.whereType<int>().toList(),
          List.generate(count, (index) => index),
        );
        expect(
          entries.where((index) => index == null),
          hasLength(adSlotCount(count)),
        );
        expect(adSlotCount(count), count <= 4 ? 1 : (count - 1) ~/ 4);
        expect(entries.last, count <= 4 ? null : count - 1);
      }
    },
  );

  for (final count in [0, 1, 4]) {
    testWidgets('grid shows a banner with $count listings', (tester) async {
      await pumpTestApp(
        tester,
        Scaffold(
          body: CustomScrollView(
            slivers: [
              AdvertisedSliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 60,
                ),
                itemCount: count,
                itemBuilder: (_, index) => Text('Listing $index'),
              ),
            ],
          ),
        ),
        overrides: [
          activeAdvertisementsProvider.overrideWith((_) async => _ads),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.byType(AdvertisementBanner), findsOneWidget);
      for (var index = 0; index < count; index++) {
        expect(find.text('Listing $index'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final mode in ['active', 'empty', 'failed']) {
    testWidgets('empty-list ad slot handles $mode ads', (tester) async {
      await pumpTestApp(
        tester,
        const Scaffold(body: AdvertisementSlot(rotationOffset: 1)),
        overrides: [
          activeAdvertisementsProvider.overrideWith((_) async {
            if (mode == 'failed') throw Exception('Ads unavailable');
            return mode == 'active' ? _ads : <Advertisement>[];
          }),
        ],
      );
      await tester.pumpAndSettle();
      expect(
        find.byType(AdvertisementBanner),
        mode == 'active' ? findsOneWidget : findsNothing,
      );
      if (mode == 'active') {
        expect(
          tester
              .widget<AdvertisementBanner>(find.byType(AdvertisementBanner))
              .advertisement
              .id,
          'a2',
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final mode in ['active', 'empty', 'failed']) {
    testWidgets(
      'grid $mode ads preserve cards and full-width banners without empty slots',
      (tester) async {
        tester.view.physicalSize = const Size(400, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await pumpTestApp(
          tester,
          Scaffold(
            body: CustomScrollView(
              slivers: [
                AdvertisedSliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: 60,
                  ),
                  itemCount: 9,
                  itemBuilder: (_, index) =>
                      Center(child: Text('Listing $index')),
                ),
              ],
            ),
          ),
          overrides: [
            activeAdvertisementsProvider.overrideWith((_) async {
              if (mode == 'failed') throw Exception('Ads unavailable');
              return mode == 'active' ? _ads : <Advertisement>[];
            }),
          ],
        );
        await tester.pumpAndSettle();
        for (var index = 0; index < 9; index++) {
          expect(find.text('Listing $index'), findsOneWidget);
        }
        expect(
          find.byType(AdvertisementBanner),
          mode == 'active' ? findsNWidgets(2) : findsNothing,
        );
        if (mode == 'active') {
          expect(
            tester.getSize(find.byType(AdvertisementBanner).first).width,
            400,
          );
          expect(
            tester
                .widget<AdvertisementBanner>(
                  find.byType(AdvertisementBanner).first,
                )
                .advertisement
                .id,
            'a1',
          );
          expect(
            tester
                .widget<AdvertisementBanner>(
                  find.byType(AdvertisementBanner).last,
                )
                .advertisement
                .id,
            'a2',
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _EmptyClosestListings extends ClosestListingsNotifier {
  @override
  Future<ClosestListingsState> build() async =>
      const ClosestListingsState(listings: PagedList(), nearUser: false);
}
