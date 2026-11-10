import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/feed/presentation/widgets/feed_header.dart';
import 'package:tilomnov/features/feed/presentation/widgets/feed_listing_card.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/presentation/widgets/property_image_gallery.dart';
import 'package:tilomnov/features/property/presentation/widgets/saved_property_card.dart';
import 'package:tilomnov/features/property/presentation/widgets/share/property_share_sheet.dart';

import '../../support/test_app.dart';

PropertyModel _property({String status = 'Active'}) => PropertyModel(
  id: 'feed-listing',
  title: 'A bright home for your next chapter',
  price: '120000',
  propertyType: 'House',
  status: status,
  createdAt: DateTime(2026, 10, 15),
  ownerId: 'publisher',
  ownerName: 'Sokha Realty',
  bedrooms: 3,
  bathrooms: 2,
  buildingSize: 120,
  priceDroppedAt: DateTime.now(),
  previousPrice: 135000,
);

Future<void> _pumpPost(
  WidgetTester tester, {
  String status = 'Active',
  bool saved = false,
  VoidCallback? onOpen,
  VoidCallback? onSave,
  VoidCallback? onMap,
  Map<String, Object> settings = const {},
  double textScale = 1,
  PropertyModel? property,
}) => pumpTestApp(
  tester,
  Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              FeedHeader(onExplore: () {}, onFilter: () {}, filterCount: 4),
              FeedListingCard(
                property: property ?? _property(status: status),
                isFavorite: saved,
                onOpen: onOpen ?? () {},
                onOpenOwner: (_) {},
                onFavoriteToggled: onSave ?? () {},
                onViewOnMap: onMap ?? () {},
              ),
            ],
          ),
        ),
      ),
    ),
  ),
  savedSettings: settings,
);

void main() {
  for (final language in ['en', 'km']) {
    for (final theme in ['light', 'dark']) {
      testWidgets('$language $theme fits a narrow phone with large text', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await _pumpPost(
          tester,
          settings: {
            'settings.language': language,
            'settings.theme_mode': theme,
          },
          textScale: 1.6,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final title = tester.getRect(find.text(_property().title));
        expect(title.left, 24);
        expect(title.right, 320 - 24);
        expect(find.byType(SavedPropertyCard), findsNothing);
        expect(find.byType(PropertyImageGallery), findsOneWidget);
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -800),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('opens a listing, saves it, maps it and opens sharing', (
    tester,
  ) async {
    var opened = 0;
    var saved = 0;
    var mapped = 0;
    await _pumpPost(
      tester,
      onOpen: () => opened++,
      onSave: () => saved++,
      onMap: () => mapped++,
    );
    await tester.tap(find.text(_property().title));
    expect(opened, 1);
    await tester.ensureVisible(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Price dropped'), findsOneWidget);
    expect(find.text(r'$ 135,000'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.tap(find.text('View on map'));
    expect(saved, 1);
    expect(mapped, 1);
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(find.byType(PropertyShareSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('swiping photos does not open the listing; tapping one does', (
    tester,
  ) async {
    var opened = 0;
    await _pumpPost(
      tester,
      property: _property().copyWith(
        imageUrls: const [
          'assets/images/homescreen/mapDefault.png',
          'assets/images/homescreen/mapSatellite.png',
        ],
      ),
      onOpen: () => opened++,
    );
    final gallery = find.byType(PropertyImageGallery);
    await tester.drag(gallery, const Offset(-700, 0));
    await tester.pumpAndSettle();
    final pages = tester.widget<PageView>(find.byType(PageView));
    expect(pages.controller!.page, 1);
    expect(opened, 0);
    await tester.tap(gallery);
    expect(opened, 1);
  });

  testWidgets(
    'unavailable posts still allow unsaving, but cannot open or share',
    (tester) async {
      var opened = false;
      var unsaved = false;
      await _pumpPost(
        tester,
        status: 'Sold',
        saved: true,
        onOpen: () => opened = true,
        onSave: () => unsaved = true,
      );
      await tester.tap(find.text(_property().title));
      expect(opened, isFalse);
      await tester.ensureVisible(find.text('Saved'));
      await tester.pumpAndSettle();
      expect(find.text('Unavailable'), findsOneWidget);
      expect(find.text('View on map'), findsNothing);
      final share = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Share'),
      );
      expect(share.onPressed, isNull);
      await tester.tap(find.text('Saved'));
      expect(unsaved, isTrue);
    },
  );
}
