import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/presentation/widgets/detail/sections/property_share_section.dart';
import 'package:tilomnov/features/property/presentation/widgets/share/property_share_card.dart';
import 'package:tilomnov/features/property/presentation/widgets/share/property_share_sheet.dart';
import 'package:tilomnov/features/property/utils/property_share_link.dart';
import 'package:tilomnov/features/property/utils/property_share_message.dart';
import 'package:tilomnov/l10n/generated/app_localizations.dart';

import '../../support/test_app.dart';

final _listing = PropertyModel.fromJson({
  'id': 'f6a20c84-5e0b-44f3-b328-c8d64411d2ec',
  'title': 'Farm house',
  'price': '500000',
  'propertyType': 'House',
  'listingType': 'Sale',
  'status': 'Active',
  'bedrooms': 4,
  'bathrooms': 5,
  'buildingSize': '300',
  'createdAt': '2026-10-18T03:09:46.148Z',
});

void main() {
  test('a listing is shared as its page on the website', () {
    expect(
      propertyShareLink(_listing.id).toString(),
      'https://tilomnov.sparkbytekh.com/property/${_listing.id}',
    );
  });

  group('the text shared with the picture', () {
    final l10n = lookupAppLocalizations(const Locale('en'));

    test('has the listing, the link and where it came from', () {
      expect(
        propertyShareMessage(l10n, _listing),
        '🏡 House for sale · \$ 500,000\n'
        '📐 4 bds · 5 ba · 300 m²\n'
        '📝 Farm house\n'
        '\n'
        '📍 See the photos and exact location on the map:\n'
        'https://tilomnov.sparkbytekh.com/property/${_listing.id}\n'
        '\n'
        'Shared from Tilomnov, land and homes on the map.',
      );
    });

    test('names a price cut, and leaves out what a listing lacks', () {
      final land = PropertyModel.fromJson({
        'id': '03fbd671-9bcb-42ec-90bf-15b65ca3c1ff',
        'title': ' ',
        'price': '70000',
        'discountType': 'percent',
        'discountValue': 10,
        'propertyType': 'Land',
        'listingType': 'Sale',
        'status': 'Active',
        'createdAt': '2026-10-18T03:09:46.148Z',
      });

      expect(
        propertyShareMessage(l10n, land),
        '🏡 Land for sale · \$ 63,000\n'
        '🔻 Price cut: 10%\n'
        '\n'
        '📍 See the photos and exact location on the map:\n'
        'https://tilomnov.sparkbytekh.com/property/${land.id}\n'
        '\n'
        'Shared from Tilomnov, land and homes on the map.',
      );
    });
  });

  testWidgets('Share shows the picture with the price, QR code and link', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: PropertyShareSection(property: _listing),
        ),
      ),
    );

    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();

    final card = find.byType(PropertyShareCard);
    expect(card, findsOneWidget);
    expect(
      find.descendant(of: card, matching: find.text(r'$ 500,000')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: card,
        matching: find.text('tilomnov.sparkbytekh.com/property/${_listing.id}'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.byType(QrImageView)),
      findsOneWidget,
    );
    expect(find.text('Copy link'), findsOneWidget);
    expect(find.text('Save image'), findsOneWidget);
  });

  testWidgets('Copy link puts the page address on the clipboard', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await pumpTestApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: PropertyShareSection(property: _listing),
        ),
      ),
    );
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy link'));
    await tester.pump();

    expect(copied, propertyShareLink(_listing.id).toString());
    // The confirmation's timer runs out before the test ends.
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  group('a listing that is not public', () {
    PropertyModel withStatus(String status) =>
        _listing.copyWith(status: status);

    testWidgets('a draft says to publish it, with no QR code to scan', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: PropertyShareSection(property: withStatus('Draft')),
          ),
        ),
      );

      expect(
        find.textContaining('Publish it to share its link'),
        findsOneWidget,
      );
      expect(find.byType(QrImageView), findsNothing);
      expect(find.text('Share'), findsNothing);
    });

    testWidgets('Share on one being paid for says when it can be shared', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  PropertyShareSheet.show(context, withStatus('Pending')),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();

      expect(find.byType(PropertyShareCard), findsNothing);
      expect(
        find.textContaining('goes public once its payment is complete'),
        findsOneWidget,
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });
  });
}
