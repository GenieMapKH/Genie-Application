import 'package:genie/features/property/data/models/property_model.dart';
import 'package:intl/intl.dart';
import 'package:genie/features/property/presentation/property_labels.dart';
import 'package:genie/l10n/l10n.dart';

/// Shared display formatting for property price, size and spec lines so the
/// map card, detail sheet and similar-property tiles stay consistent.
class PropertyFormat {
  static final NumberFormat _price = NumberFormat.currency(
    symbol: '\$ ',
    decimalDigits: 0,
  );
  static final NumberFormat _compact = NumberFormat.decimalPattern();
  static final NumberFormat _shortMoney = NumberFormat.compactCurrency(
    symbol: '\$',
  );

  /// `$ 105,400`
  static String price(String raw) {
    return _price.format(double.tryParse(raw) ?? 0.0);
  }

  /// `$ 105,400` from a number, e.g. a listing's discounted price.
  static String money(double value) => _price.format(value);

  /// `$500K`, `$1.2M`: a price where space is short.
  static String shortMoney(double value) => _shortMoney.format(value);

  /// Trims the trailing `.0` so 1670.0 renders as `1670` but 83.5 stays `83.5`.
  static String size(double value) {
    return value == value.roundToDouble()
        ? value.round().toString()
        : value.toStringAsFixed(1);
  }

  /// `1,688` — used for view/save/contact counters.
  static String count(int value) => _compact.format(value);

  /// A card's price: `$ 105,400`, `$ 500 / month` for a rental, or
  /// `From $ 45,000` for a Borey, whose price is its cheapest unit.
  static String cardPrice(AppLocalizations l10n, PropertyModel property) {
    final amount = money(property.finalPrice);
    if (property.propertyType == 'Borey') return l10n.propertyPriceFrom(amount);
    if (property.isRental) return l10n.propertyFactPerMonth(amount);
    return amount;
  }

  /// The bedrooms a card shows: `Studio` for a condo with none, or null
  /// when the type has no rooms or none were given.
  static String? cardBedrooms(AppLocalizations l10n, PropertyModel property) {
    final bedrooms = property.bedrooms;
    if (!property.hasRooms || bedrooms == null) return null;
    if (bedrooms == 0) {
      return property.propertyType == 'Condo'
          ? l10n.propertyOptionStudio
          : null;
    }
    return l10n.propertySpecBeds(bedrooms);
  }

  /// `House for sale` or `House for rent`, in the user's language.
  static String typeAndListing(AppLocalizations l10n, PropertyModel property) {
    final type = propertyValueLabel(l10n, property.propertyType);
    return property.isRental
        ? l10n.propertyTypeForRent(type)
        : l10n.propertyTypeForSale(type);
  }

  /// The map card's middle line: `1670 m² | Land for sale` for land, or
  /// `4 bds | 5 ba | 115.5 m² | House for sale` for a house, in the user's
  /// language. Only what the type's form asks for is shown.
  static String cardSpecLine(AppLocalizations l10n, PropertyModel property) {
    final bathrooms = property.bathrooms;
    final displaySize = property.displaySize;
    return [
      ?cardBedrooms(l10n, property),
      if (property.hasRooms && bathrooms != null && bathrooms > 0)
        l10n.propertySpecBaths(bathrooms),
      if (displaySize != null) '${size(displaySize)} m²',
      typeAndListing(l10n, property),
    ].join(' | ');
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
