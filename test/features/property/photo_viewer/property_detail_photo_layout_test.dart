import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tilomnov/features/property/presentation/widgets/detail/property_detail_photo_layout.dart';
import 'package:tilomnov/features/property/presentation/widgets/photo_viewer/property_photo_viewer.dart';
import 'package:tilomnov/l10n/generated/app_localizations.dart';

const _photo = 'assets/images/brand/app_icon.png';
const _sheet = Size(400, 760);

Future<void> _pumpLayout(WidgetTester tester, {int photos = 6}) {
  tester.view.physicalSize = _sheet;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final urls = List.filled(photos, _photo);
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PropertyDetailPhotoLayout(
            imageUrls: urls,
            thumbnailUrls: urls,
            propertyId: 'p1',
            onPhotosScrolled: (_) => false,
            body: const SizedBox(height: 1200, child: Text('Price')),
          ),
        ),
      ),
    ),
  );
}

double _cardTop(WidgetTester tester) =>
    tester.getTopLeft(find.text('Price')).dy;

void main() {
  testWidgets('the description rests under the first photo', (tester) async {
    await _pumpLayout(tester);
    await tester.pumpAndSettle();

    final photo = PropertyDetailPhotoLayout.photoHeightFor(_sheet.width);
    expect(_cardTop(tester), closeTo(photo - 20, 1));
    expect(find.text('1 / 6'), findsOneWidget);
  });

  testWidgets(
    'scrolling the photos lowers the description to a peek, dragging it brings it back',
    (tester) async {
      await _pumpLayout(tester);
      await tester.pumpAndSettle();
      final resting = _cardTop(tester);

      // On the photo above the card.
      await tester.dragFrom(const Offset(200, 100), const Offset(0, -150));
      await tester.pumpAndSettle();
      expect(
        _cardTop(tester),
        closeTo(_sheet.height - PropertyDetailPhotoLayout.peekHeight, 1),
      );

      // Up from the peek: back to resting under the first photo.
      await tester.dragFrom(const Offset(200, 680), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(_cardTop(tester), closeTo(resting, 1));
    },
  );

  testWidgets('tapping a photo opens it full screen', (tester) async {
    await _pumpLayout(tester);
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(200, 100));
    await tester.pumpAndSettle();
    expect(find.byType(PropertyPhotoViewer), findsOneWidget);
  });
}
