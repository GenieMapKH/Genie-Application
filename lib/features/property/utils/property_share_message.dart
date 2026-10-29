import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/utils/property_format.dart';
import 'package:tilomnov/features/property/utils/property_share_link.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// The text a listing is shared with, beside its picture:
///
/// ```text
/// 🏡 House for sale · $ 500,000
/// 🔻 Price cut: 10%
/// 📐 4 bds · 5 ba · 300 m²
/// 📝 Farm house
///
/// 📍 See the photos and exact location on the map:
/// https://tilomnov.sparkbytekh.com/property/…
///
/// Shared from Tilomnov, land and homes on the map.
/// ```
///
/// Lines with nothing to say (no discount, no sizes, no title) are left out.
String propertyShareMessage(AppLocalizations l10n, PropertyModel property) {
  final title = property.title.trim();
  final bathrooms = property.bathrooms;
  final displaySize = property.displaySize;
  final specs = [
    ?PropertyFormat.cardBedrooms(l10n, property),
    if (property.hasRooms && bathrooms != null && bathrooms > 0)
      l10n.propertySpecBaths(bathrooms),
    if (displaySize != null) '${PropertyFormat.size(displaySize)} m²',
  ];

  return [
    '🏡 ${PropertyFormat.typeAndListing(l10n, property)} · '
        '${PropertyFormat.cardPrice(l10n, property)}',
    if (property.hasDiscount)
      '🔻 ${l10n.propertyPriceCut(_discount(property))}',
    if (specs.isNotEmpty) '📐 ${specs.join(' · ')}',
    if (title.isNotEmpty) '📝 $title',
    '',
    '📍 ${l10n.propertyShareMessageSeeOnMap}',
    propertyShareLink(property.id).toString(),
    '',
    l10n.propertyShareMessageFooter,
  ].join('\n');
}

/// `10%` or `$ 5,000`, as the detail sheet's price-cut chip writes it.
String _discount(PropertyModel property) {
  final value = property.discountValue!;
  return property.discountType == 'percent'
      ? '${PropertyFormat.size(value)}%'
      : PropertyFormat.money(value);
}
