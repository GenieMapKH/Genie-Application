import 'package:genie/features/property/data/models/property_model.dart';
import 'package:intl/intl.dart';

/// Shared display formatting for property price, size and spec lines so the
/// map card, detail sheet and similar-property tiles stay consistent.
class PropertyFormat {
  static final NumberFormat _price = NumberFormat.currency(
    symbol: '\$ ',
    decimalDigits: 0,
  );
  static final NumberFormat _compact = NumberFormat.decimalPattern();

  /// `$ 105,400`
  static String price(String raw) {
    return _price.format(double.tryParse(raw) ?? 0.0);
  }

  /// Trims the trailing `.0` so 1670.0 renders as `1670` but 83.5 stays `83.5`.
  static String size(double value) {
    return value == value.roundToDouble()
        ? value.round().toString()
        : value.toStringAsFixed(1);
  }

  /// `1,688` — used for view/save/contact counters.
  static String count(int value) => _compact.format(value);

  /// The map card's middle line: `1670 m² | Land for sale` for land, or
  /// `4 bds | 5 ba | 115.5 m² | House for sale` for built property.
  static String cardSpecLine(PropertyModel property) {
    final parts = <String>[];

    if (property.bedrooms != null && property.bedrooms! > 0) {
      parts.add('${property.bedrooms} bds');
    }
    if (property.bathrooms != null && property.bathrooms! > 0) {
      parts.add('${property.bathrooms} ba');
    }

    final displaySize = property.displaySize;
    if (displaySize != null) {
      parts.add('${size(displaySize)} m²');
    }

    parts.add('${property.propertyType} for sale');
    return parts.join(' | ');
  }

  /// The detail sheet's spec row uses long labels: `2 Beds`, `2 Baths`.
  static String bedroomLabel(int count) => '$count ${count == 1 ? 'Bed' : 'Beds'}';

  static String bathroomLabel(int count) =>
      '$count ${count == 1 ? 'Bath' : 'Baths'}';

  /// `165 days` on the detail sheet's stat row.
  static String daysListed(PropertyModel property) {
    final days = property.daysListed;
    return '$days ${days == 1 ? 'day' : 'days'}';
  }

  /// The SVG used for the property-type pill on cards and tiles.
  static String typeIconPath(String propertyType) {
    switch (propertyType) {
      case 'House':
        return 'assets/icons/property_house.svg';
      case 'Building':
        return 'assets/icons/property_building.svg';
      case 'Condo':
        return 'assets/icons/property_condo.svg';
      case 'Borey':
        return 'assets/icons/property_borey.svg';
      case 'Business for Sale':
        return 'assets/icons/property_business.svg';
      case 'Warehouse':
        return 'assets/icons/property_warehouse.svg';
      case 'Land':
      default:
        return 'assets/icons/property_land.svg';
    }
  }
}
