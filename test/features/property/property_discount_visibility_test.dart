import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/presentation/view_models/add_property_controller.dart';
import 'package:genie/features/property/presentation/view_models/property_form_input.dart';
import 'package:genie/features/property/presentation/view_models/property_visibility.dart';
import 'package:genie/features/property/presentation/widgets/detail/header/property_detail_summary.dart';
import 'package:genie/l10n/generated/app_localizations.dart';

PropertyModel _listing({
  String? type,
  String? value,
  String status = 'Active',
}) => PropertyModel.fromJson({
  'id': 'p-1',
  'title': 'Villa',
  'price': '100000',
  'propertyType': 'House',
  'status': status,
  'createdAt': '2026-10-01T00:00:00.000Z',
  'discountType': type,
  'discountValue': value,
});

void main() {
  group('discount', () {
    test('the buyer pays the asking price less the discount', () {
      expect(_listing().finalPrice, 100000);
      expect(_listing().hasDiscount, isFalse);
      expect(_listing(type: 'percent', value: '20.00').finalPrice, 80000);
      expect(_listing(type: 'amount', value: '5000.00').finalPrice, 95000);
      expect(_listing(type: 'amount', value: '5000.00').formattedPrice, '95K');
    });

    test('the form sends the discount only when one is typed', () {
      expect(
        const PropertyFormInput(price: '100000').toRequestBody(),
        containsPair('discountType', null),
      );
      final body = const PropertyFormInput(
        price: '100000',
        discount: '5,000',
        discountType: 'amount',
      ).toRequestBody();
      expect(body['discountType'], 'amount');
      expect(body['discountValue'], 5000.0);
    });

    test('editing opens the form with the discount as entered', () {
      final input = PropertyFormInput.fromProperty(
        _listing(type: 'percent', value: '12.50'),
      );
      expect(input.discount, '12.5');
      expect(input.discountType, 'percent');
    });

    test('a discount must leave a price above zero', () {
      bool ok(String discount, String type) => isValidDiscount(
        discount: discount,
        discountType: type,
        price: '100000',
      );

      expect(ok('', 'percent'), isTrue);
      expect(ok('20', 'percent'), isTrue);
      expect(ok('100', 'percent'), isFalse);
      expect(ok('0', 'percent'), isFalse);
      expect(ok('99999', 'amount'), isTrue);
      expect(ok('100000', 'amount'), isFalse);
      expect(ok('abc', 'amount'), isFalse);
    });

    testWidgets('shows the old price crossed out above the new one', (
      tester,
    ) async {
      Future<void> show(PropertyModel property) => tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: PropertyDetailSummary(property: property)),
          ),
        ),
      );

      await show(_listing(type: 'percent', value: '20'));
      expect(find.text('Price cut: 20%'), findsOneWidget);
      final old = tester.widget<Text>(find.text('\$ 100,000'));
      expect(old.style?.decoration, TextDecoration.lineThrough);
      expect(find.text('\$ 80,000'), findsOneWidget);

      await show(_listing());
      expect(find.textContaining('Price cut'), findsNothing);
      expect(find.text('\$ 100,000'), findsOneWidget);
    });
  });

  group('visibility', () {
    test('only moves the server allows', () {
      expect(
        visibilityChange('Draft', PropertyVisibility.public),
        VisibilityChange.publish,
      );
      expect(
        visibilityChange('Sold', PropertyVisibility.public),
        VisibilityChange.relist,
      );
      expect(
        visibilityChange('Active', PropertyVisibility.draft),
        VisibilityChange.unpublish,
      );
      expect(
        visibilityChange('Active', PropertyVisibility.sold),
        VisibilityChange.markSold,
      );
      // A draft must be public before it can be sold.
      expect(visibilityChange('Draft', PropertyVisibility.sold), isNull);
      // Already there, or mid-payment.
      expect(visibilityChange('Active', PropertyVisibility.public), isNull);
      expect(visibilityChange('Pending', PropertyVisibility.public), isNull);
    });
  });
}
