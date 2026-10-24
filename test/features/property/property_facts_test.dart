import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/property/data/models/property_details.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/presentation/view_models/property_facts.dart';
import 'package:genie/l10n/generated/app_localizations.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  PropertyModel listing({
    String type = 'Condo',
    String? listingType = 'Sale',
    int? bedrooms,
    double? unitSize,
    PropertyDetails details = const PropertyDetails(),
  }) {
    return PropertyModel(
      id: 'p-1',
      title: 'Unit',
      price: '120000',
      propertyType: type,
      listingType: listingType,
      status: 'Active',
      createdAt: DateTime(2026),
      bedrooms: bedrooms,
      unitSize: unitSize,
      details: details,
    );
  }

  Map<String, Map<String, String>> asMap(List<PropertyFactGroup> groups) => {
    for (final group in groups)
      group.title: {for (final fact in group.facts) fact.label: fact.value},
  };

  test('a condo shows what its form asked, grouped, and nothing else', () {
    final groups = asMap(
      propertyFactGroups(
        l10n,
        listing(
          bedrooms: 0,
          unitSize: 60,
          details: const PropertyDetails(
            titleType: 'Hard Title',
            floors: 30,
            floorNumber: 12,
            hasBalcony: true,
            furnishing: 'Fully Furnished',
            completionStatus: 'Completed',
            viewType: 'River View',
            maintenanceFee: 50,
          ),
        ),
      ),
    );

    expect(groups.keys, [
      'Overview',
      'Size',
      'Rooms & Building',
      'Costs & Business',
    ]);
    expect(groups['Overview'], {
      'Property Type': 'Condo',
      'Listing Type': 'Sale',
      'Title Type': 'Hard Title',
      'Completion Status': 'Completed',
      'Price per m²': r'$ 2,000',
    });
    expect(groups['Size'], {'Unit Size': '60 m²'});
    expect(groups['Rooms & Building'], {
      'Bedrooms': 'Studio',
      'Total Floors': '30',
      'Floor Number': '12',
      'Balcony': 'Yes',
      'Furnished': 'Fully Furnished',
      'View Type': 'River View',
    });
    expect(groups['Costs & Business'], {'Maintenance Fee': r'$ 50 / month'});
  });

  test('a rental has no price per m²: its price is per month', () {
    final groups = asMap(
      propertyFactGroups(l10n, listing(listingType: 'Rent', unitSize: 60)),
    );

    expect(groups['Overview']!.containsKey('Price per m²'), isFalse);
  });

  test('a business shows its rent, lease and reason, blanks left out', () {
    final groups = asMap(
      propertyFactGroups(
        l10n,
        listing(
          type: 'Business for Sale',
          details: const PropertyDetails(
            monthlyRent: 800,
            leaseRemainingMonths: 18,
            equipmentIncluded: '  ',
            reasonForSelling: 'Moving abroad',
          ),
        ),
      ),
    );

    expect(groups['Costs & Business'], {
      'Monthly Rent': r'$ 800 / month',
      'Lease Remaining': '18 months',
      'Reason for Selling': 'Moving abroad',
    });
  });
}
