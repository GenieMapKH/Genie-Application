import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/property/data/models/map_property_filter.dart';
import 'package:tilomnov/features/property/data/models/takeover_terms.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_form_input.dart';
import 'takeover_fixture.dart';

void main() {
  test('takeover terms round-trip through a listing and its edit request', () {
    final property = takeoverListingFixture();
    final body = PropertyFormInput.fromProperty(property).toRequestBody();
    expect(body['takeover'], takeoverFixture.toJson());
    expect(body['listingType'], takeoverListingType);
    expect(body['price'], 80000.25);
    expect(body['discountValue'], isNull);
    expect(property.copyWith(title: 'Edited').takeover, property.takeover);
  });

  test(
    'the combined price includes the balance only once, preserving cents',
    () {
      expect(takeoverFixture.errors, isEmpty);
      expect(takeoverFixture.combinedPrice, 80000.25);
    },
  );

  for (final field in [
    'providerType',
    'providerName',
    'projectName',
    'sellerAmount',
    'remainingBalance',
    'balanceAsOf',
    'paymentAmount',
    'paymentFrequency',
    'remainingMonths',
    'nextPaymentDate',
    'interestType',
    'annualInterestRate',
    'transferStatus',
    'transferFeePayer',
    'arrearsAmount',
    'hasAdditionalPayments',
  ]) {
    test('publishing requires $field', () {
      final terms = TakeoverTerms.fromJson({
        ...takeoverFixture.toJson(),
        field: null,
      });
      expect(terms.errors, contains(field));
    });
  }

  test(
    'invalid dates, non-transferable contracts and invalid amounts fail',
    () {
      final terms = TakeoverTerms.fromJson({
        ...takeoverFixture.toJson(),
        'balanceAsOf': '2026-02-30',
        'transferStatus': 'Not allowed',
        'sellerAmount': -1,
        'paymentAmount': 0,
        'remainingMonths': 0,
        'arrearsAmount': 100,
        'arrearsPayer': null,
      });
      expect(
        terms.errors,
        containsAll([
          'balanceAsOf',
          'transferStatus',
          'sellerAmount',
          'paymentAmount',
          'remainingMonths',
          'arrearsPayer',
        ]),
      );
    },
  );

  test(
    'a larger scheduled payment needs an amount/date and must fit the balance',
    () {
      for (final payments in [
        <Map<String, dynamic>>[],
        [
          {'amount': 60001, 'dueDate': '2027-01-01'},
        ],
        [
          {'amount': 100, 'dueDate': null},
        ],
      ]) {
        final terms = TakeoverTerms.fromJson({
          ...takeoverFixture.toJson(),
          'additionalPayments': payments,
        });
        expect(terms.errors, contains('additionalPayments'));
      }
    },
  );

  test(
    'ordinary sales clear takeover terms, even after changing the selection',
    () {
      final body = PropertyFormInput(
        listingType: 'Sale',
        takeover: takeoverFixture,
      ).toRequestBody();
      expect(body['takeover'], isNull);
    },
  );

  test('sale and takeover-only filters both find a takeover listing', () {
    final listing = takeoverListingFixture();
    expect(
      const MapPropertyFilter(
        listingTypes: MapPropertyFilter.forSale,
      ).matches(listing),
      isTrue,
    );
    expect(
      const MapPropertyFilter(
        listingTypes: [takeoverListingType],
      ).matches(listing),
      isTrue,
    );
    expect(
      const MapPropertyFilter(
        listingTypes: MapPropertyFilter.forRent,
      ).matches(listing),
      isFalse,
    );
    expect(const MapPropertyFilter(maxPrice: 30000).matches(listing), isFalse);
  });
}
