import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tilomnov/features/property/presentation/widgets/detail/header/property_detail_gallery.dart';
import 'package:tilomnov/features/property/presentation/widgets/photo_viewer/photo_watermark.dart';
import 'package:tilomnov/features/property/presentation/widgets/photo_viewer/property_photo_viewer.dart';
import 'package:tilomnov/l10n/generated/app_localizations.dart';

const _photo = 'assets/images/brand/app_icon.png';

Future<void> _pumpCover(WidgetTester tester, int photos) {
  final urls = List.filled(photos, _photo);
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              PropertyDetailGallery(
                imageUrls: urls,
                thumbnailUrls: urls,
                propertyId: 'p1',
              ),
              const SliverToBoxAdapter(child: Text('Price')),
            ],
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('the price starts at the same place for one or many photos', (
    tester,
  ) async {
    await _pumpCover(tester, 1);
    final withOne = tester.getTopLeft(find.text('Price')).dy;
    expect(find.text('1 / 1'), findsNothing);

    await _pumpCover(tester, 8);
    expect(tester.getTopLeft(find.text('Price')).dy, withOne);
    expect(find.text('1 / 8'), findsOneWidget);
    expect(find.byType(PhotoWatermark), findsOneWidget);
  });

  testWidgets('swipes sideways and opens the photo shown full screen', (
    tester,
  ) async {
    await _pumpCover(tester, 3);

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);

    await tester.tap(find.byType(PageView));
    await tester.pumpAndSettle();
    expect(find.byType(PropertyPhotoViewer), findsOneWidget);
    expect(find.byTooltip('Save photo'), findsOneWidget);
    // The viewer keeps the mark on screen, so screenshots carry it.
    expect(
      find.descendant(
        of: find.byType(PropertyPhotoViewer),
        matching: find.byType(PhotoWatermark),
      ),
      findsOneWidget,
    );

    final viewerPages = find.descendant(
      of: find.byType(PropertyPhotoViewer),
      matching: find.byType(PageView),
    );
    await tester.fling(viewerPages, const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(PropertyPhotoViewer),
        matching: find.text('3 / 3'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(PropertyPhotoViewer), findsNothing);
    // Back on the photo looked at last.
    expect(find.text('3 / 3'), findsOneWidget);
  });
}
