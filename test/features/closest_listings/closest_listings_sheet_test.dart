import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tilomnov/features/closest_listings/data/closest_listings_repository.dart';
import 'package:tilomnov/features/closest_listings/presentation/closest_sheet_layout.dart';
import 'package:tilomnov/features/closest_listings/presentation/view_models/closest_listings_provider.dart';
import 'package:tilomnov/features/closest_listings/presentation/widgets/closest_glass_handle.dart';
import 'package:tilomnov/features/closest_listings/presentation/widgets/closest_listing_tile.dart';
import 'package:tilomnov/features/closest_listings/presentation/widgets/closest_listings_sheet.dart';
import 'package:tilomnov/features/property/data/repositories/favorites_repository.dart';
import 'package:tilomnov/features/property/presentation/view_models/map_property_filter.dart';
import 'package:tilomnov/features/property/presentation/view_models/saved_property_ids_provider.dart';

import '../../support/test_app.dart';

String _listing(int n) =>
    '{"id": "p-$n", "title": "Listing $n", "price": "120000", '
    '"propertyType": "Land", "listingType": "Sale", "status": "Active", '
    '"createdAt": "2026-07-01T00:00:00.000Z", "lat": 11.55, "lng": 104.92, '
    '"images": [], "user": {"id": "owner", "name": "Sokha"}, '
    '"distanceMeters": ${n * 450}}';

/// [total] listings, answered a page at a time as the server does, or a
/// failure while [fail] is set.
class _Api {
  final int total;
  bool fail = false;

  /// The query of each request for the list, in order.
  final List<Map<String, dynamic>> asked = [];
  late final server = StubServer(_respond);

  _Api(this.total);

  (int, String) _respond(RequestOptions options) {
    if (options.path == '/properties/my/favorites/ids') return (200, '[]');
    if (options.path != '/public/properties/closest') return (404, '{}');
    final query = options.queryParameters;
    asked.add(query);
    if (fail) return (500, '{}');
    final offset = query['offset'] as int;
    final limit = query['limit'] as int;
    final end = (offset + limit).clamp(0, total);
    final items = [for (var n = offset + 1; n <= end; n++) _listing(n)];
    final next = end < total ? '$end' : 'null';
    return (200, '{"items": [${items.join(', ')}], "nextOffset": $next}');
  }
}

/// The user, or the map's centre when [isUser] is false; counts its reads.
class _Origin {
  bool isUser;
  int reads = 0;

  _Origin({this.isUser = true});

  Future<ClosestOrigin> call() async {
    reads++;
    return (point: const LatLng(11.556, 104.928), isUser: isUser);
  }
}

/// The map screen's arrangement: the sheet between the top and the nav.
Future<ProviderContainer> _pump(
  WidgetTester tester,
  _Api api, {
  Size size = const Size(390, 844),
  double textScale = 1,
  _Origin? origin,
  bool glass = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await pumpTestApp(
    tester,
    Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: Colors.green)),
          Positioned(
            left: 0,
            right: 0,
            top: 8,
            bottom: 98,
            child: ClosestListingsSheet(visible: true, glass: glass),
          ),
        ],
      ),
    ),
    overrides: [
      closestListingsRepositoryProvider.overrideWithValue(
        ClosestListingsRepository(api.server.dio),
      ),
      closestOriginProvider.overrideWithValue((origin ?? _Origin()).call),
      favoritesRepositoryProvider.overrideWithValue(
        FavoritesRepository(api.server.dio),
      ),
      signedInOverride(signedIn: false),
    ],
  );
  return ProviderScope.containerOf(
    tester.element(find.byType(ClosestListingsSheet)),
  );
}

/// Lets the listings be parsed (`compute` runs on real time), then draws.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

Finder get _handle => find.bySemanticsLabel('Show listings near you');

Future<void> _pullUp(WidgetTester tester) async {
  await tester.tap(_handle);
  await _settle(tester);
}

Future<void> _pullAllTheWayUp(WidgetTester tester) async {
  await tester.drag(_handle, const Offset(0, -2000));
  await _settle(tester);
}

void main() {
  testWidgets('rests as a handle and reads nothing until pulled up', (
    tester,
  ) async {
    final api = _Api(3);
    await _pump(tester, api);

    expect(_handle, findsOneWidget);
    expect(find.byType(ClosestListingTile).hitTestable(), findsNothing);
    expect(api.asked, isEmpty);

    await _pullUp(tester);

    expect(api.asked.single, containsPair('lat', 11.556));
    expect(api.asked.single, containsPair('offset', 0));
    expect(find.text('Listings near you'), findsOneWidget);
    expect(find.text('450 m away'), findsOneWidget);
    expect(find.text('Listing 1'), findsOneWidget);
  });

  testWidgets('reads the next page when scrolled to the end', (tester) async {
    final api = _Api(25);
    await _pump(tester, api);
    await _pullAllTheWayUp(tester);

    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, -20000),
      3000,
    );
    await _settle(tester);

    expect(api.asked.map((q) => q['offset']), [0, 20]);
    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, -20000),
      3000,
    );
    await _settle(tester);
    expect(find.text('Listing 25'), findsOneWidget);
  });

  testWidgets('asks again with the new filter, from the same place', (
    tester,
  ) async {
    final api = _Api(3);
    final origin = _Origin();
    final container = await _pump(tester, api, origin: origin);
    await _pullUp(tester);

    container.read(mapPropertyFilterProvider.notifier).state =
        const MapPropertyFilter(propertyType: 'House');
    await _settle(tester);

    expect(api.asked.last, containsPair('propertyType', 'House'));
    expect(origin.reads, 1);
  });

  testWidgets('measuring again reads where the user is now', (tester) async {
    final api = _Api(3);
    final origin = _Origin();
    await _pump(tester, api, origin: origin);
    await _pullUp(tester);

    await tester.tap(find.byTooltip('Measure from where I am now'));
    await _settle(tester);

    expect(origin.reads, 2);
    expect(api.asked, hasLength(2));
  });

  testWidgets('says when it measures from the map instead of the user', (
    tester,
  ) async {
    await _pump(tester, _Api(3), origin: _Origin(isUser: false));
    await _pullUp(tester);

    expect(find.text('Listings near the map centre'), findsOneWidget);
  });

  testWidgets('says when nothing was found or loading failed', (tester) async {
    final api = _Api(0);
    await _pump(tester, api);
    await _pullUp(tester);
    expect(find.text('No listings found'), findsOneWidget);

    api.fail = true;
    await tester.tap(find.byTooltip('Measure from where I am now'));
    await _settle(tester);
    expect(find.text('Listings could not be loaded.'), findsOneWidget);

    api.fail = false;
    await tester.tap(find.text('Retry'));
    await _settle(tester);
    expect(find.text('No listings found'), findsOneWidget);
  });

  testWidgets('Back lets the pulled-up sheet down', (tester) async {
    await _pump(tester, _Api(3));
    await _pullAllTheWayUp(tester);
    expect(find.byType(ClosestListingTile).hitTestable(), findsWidgets);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(ClosestListingTile).hitTestable(), findsNothing);
    expect(_handle, findsOneWidget);
  });

  testWidgets('with glass navigation the resting handle is a glass pill', (
    tester,
  ) async {
    await _pump(tester, _Api(3), glass: true);

    double pillOpacity() => tester
        .widget<AnimatedOpacity>(
          find.descendant(
            of: find.byType(ClosestGlassHandle),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity;

    expect(find.byType(ClosestGlassHandle), findsOneWidget);
    expect(pillOpacity(), 1);

    // Touches go through the pill to the sheet's own handle.
    await _pullUp(tester);
    expect(find.byType(ClosestListingTile).hitTestable(), findsWidgets);
    expect(pillOpacity(), 0);
  });

  testWidgets('without glass navigation there is no glass pill', (
    tester,
  ) async {
    await _pump(tester, _Api(3));

    expect(find.byType(ClosestGlassHandle), findsNothing);
  });

  group('follows a finger', () {
    /// Where the visible panel's top edge is.
    double panelTop(WidgetTester tester) =>
        tester.getTopLeft(find.byType(CustomScrollView)).dy;

    testWidgets('rises with the finger and stays where it is held', (
      tester,
    ) async {
      await _pump(tester, _Api(8));
      final rest = panelTop(tester);
      final finger = await tester.startGesture(tester.getCenter(_handle));

      var previous = rest;
      for (var step = 0; step < 12; step++) {
        await finger.moveBy(const Offset(0, -20));
        await tester.pump(const Duration(milliseconds: 16));
        final top = panelTop(tester);
        // Never falls back down while the finger goes up.
        expect(top, lessThanOrEqualTo(previous), reason: 'step $step');
        previous = top;
      }
      // 240 px of finger travel less the touch slop: it is up there.
      expect(rest - previous, greaterThan(200));
      await finger.up();
    });

    testWidgets('keeps following when the listings arrive mid-drag', (
      tester,
    ) async {
      await _pump(tester, _Api(8));
      final rest = panelTop(tester);
      final finger = await tester.startGesture(tester.getCenter(_handle));

      var previous = rest;
      for (var step = 0; step < 12; step++) {
        await finger.moveBy(const Offset(0, -20));
        // The first pull starts reading; its answer lands while dragging.
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 15)),
        );
        await tester.pump(const Duration(milliseconds: 16));
        final top = panelTop(tester);
        expect(top, lessThanOrEqualTo(previous), reason: 'step $step');
        previous = top;
      }
      expect(rest - previous, greaterThan(200));
      await finger.up();
      await _settle(tester);
      expect(find.text('Listing 1'), findsOneWidget);
    });

    testWidgets('a short swipe settles on a stop, a flick goes all the way', (
      tester,
    ) async {
      await _pump(tester, _Api(8));
      final rest = panelTop(tester);

      await tester.drag(_handle, const Offset(0, -150));
      await _settle(tester);
      final middle = panelTop(tester);
      expect(middle, lessThan(rest - 150));

      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, -300),
        2500,
      );
      await _settle(tester);
      expect(panelTop(tester), lessThan(middle));
    });

    testWidgets('swiping down lets it back to the handle', (tester) async {
      await _pump(tester, _Api(8));
      final rest = panelTop(tester);
      await _pullAllTheWayUp(tester);
      expect(panelTop(tester), lessThan(rest - 300));

      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 900),
        3000,
      );
      await _settle(tester);
      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 900),
        3000,
      );
      await _settle(tester);

      expect(panelTop(tester), rest);
    });
  });

  group('fits every screen', () {
    const screens = <String, Size>{
      'small phone': Size(320, 568),
      'phone': Size(390, 844),
      'large phone': Size(480, 1000),
      'narrow tablet': Size(700, 1000),
      'phone sideways': Size(844, 390),
      'tablet': Size(1024, 1366),
      'tablet sideways': Size(1366, 1024),
    };

    for (final MapEntry(key: name, value: size) in screens.entries) {
      for (final textScale in [1.0, 1.6]) {
        testWidgets('$name at text size $textScale', (tester) async {
          await _pump(tester, _Api(6), size: size, textScale: textScale);
          await _pullAllTheWayUp(tester);

          expect(tester.takeException(), isNull);
          final tiles = find.byType(ClosestListingTile);
          expect(tiles, findsWidgets);

          final sheet = tester.getRect(find.byType(DraggableScrollableSheet));
          final docked = ClosestSheetLayout.isDocked(size.width);
          expect(sheet.width, ClosestSheetLayout.width(size.width));
          expect(sheet.left, docked ? ClosestSheetLayout.dockMargin : 0);
          expect(sheet.right, lessThanOrEqualTo(size.width));

          // A whole card fits in the sheet, header included.
          final first = tester.getRect(tiles.at(0));
          expect(first.height, lessThan(sheet.height - 60));
          expect(first.width, greaterThanOrEqualTo(240));
          expect(first.right, lessThanOrEqualTo(sheet.right));

          // Cards sit side by side exactly when the layout asks for columns.
          final columns = ClosestSheetLayout.columns(sheet.width);
          if (tiles.evaluate().length > 1) {
            final second = tester.getRect(tiles.at(1));
            expect(first.top == second.top, columns > 1);
          } else {
            expect(columns, 1);
          }
        });
      }
    }
  });
}
