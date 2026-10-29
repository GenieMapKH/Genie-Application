import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/presentation/property_labels.dart';
import 'package:tilomnov/features/property/utils/property_format.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// One line of the listing's details: "Parking" — "Yes".
class PropertyFact {
  final String label;
  final String value;

  const PropertyFact(this.label, this.value);
}

/// Details shown under one heading, e.g. "Size".
class PropertyFactGroup {
  final String title;
  final List<PropertyFact> facts;

  const PropertyFactGroup(this.title, this.facts);
}

/// Everything the seller entered on the listing form, grouped for reading.
/// Only what the listing has is shown: each type asks different questions
/// (see the add-property forms), and a group left empty is dropped.
List<PropertyFactGroup> propertyFactGroups(
  AppLocalizations l10n,
  PropertyModel property,
) {
  final details = property.details;
  String value(String raw) => propertyValueLabel(l10n, raw);
  String area(double size) => '${PropertyFormat.size(size)} m²';
  String yesNo(bool flag) =>
      flag ? l10n.propertyOptionYes : l10n.propertyOptionNo;

  final groups = [
    PropertyFactGroup(l10n.propertyFactsOverview, [
      PropertyFact(l10n.propertyPropertyType, value(property.propertyType)),
      if (property.listingType != null)
        PropertyFact(l10n.listingTypeTitle, value(property.listingType!)),
      if (details.titleType != null)
        PropertyFact(l10n.propertyTitleType, value(details.titleType!)),
      if (details.completionStatus != null)
        PropertyFact(
          l10n.propertyCompletionStatus,
          value(details.completionStatus!),
        ),
      if (_pricePerSquareMetre(property) case final perMetre?)
        PropertyFact(
          l10n.propertyFactPricePerSquareMetre,
          PropertyFormat.money(perMetre),
        ),
    ]),
    PropertyFactGroup(l10n.propertyFactsSize, [
      if (_positive(property.landSize) case final size?)
        PropertyFact(l10n.propertyLandSizeTitle, area(size)),
      if (_positive(property.buildingSize) case final size?)
        PropertyFact(l10n.propertyBuildingSize, area(size)),
      if (_positive(property.unitSize) case final size?)
        PropertyFact(l10n.propertyUnitSize, area(size)),
      if (_positive(details.totalProjectArea) case final size?)
        PropertyFact(l10n.propertyTotalProjectArea, area(size)),
    ]),
    PropertyFactGroup(l10n.propertyFactsBuilding, [
      if (property.bedrooms != null)
        PropertyFact(l10n.propertyBedrooms, _bedrooms(l10n, property)),
      if (property.bathrooms != null)
        PropertyFact(l10n.propertyBathrooms, '${property.bathrooms}'),
      if (details.buildingType != null)
        PropertyFact(l10n.propertyBuildingType, value(details.buildingType!)),
      if (details.floors != null)
        PropertyFact(_floorsLabel(l10n, property), '${details.floors}'),
      if (details.floorNumber != null)
        PropertyFact(l10n.propertyFloorNumber, '${details.floorNumber}'),
      if (details.totalUnits != null)
        PropertyFact(l10n.propertyTotalUnits, '${details.totalUnits}'),
      if (details.hasParking != null)
        PropertyFact(l10n.propertyParking, yesNo(details.hasParking!)),
      if (details.hasBalcony != null)
        PropertyFact(l10n.propertyBalcony, yesNo(details.hasBalcony!)),
      if (details.furnishing != null)
        PropertyFact(l10n.propertyFurnished, value(details.furnishing!)),
      if (details.viewType != null)
        PropertyFact(l10n.propertyViewType, value(details.viewType!)),
    ]),
    PropertyFactGroup(l10n.propertyFactsProject, [
      if (_text(details.developerName) case final name?)
        PropertyFact(l10n.propertyDeveloperName, name),
      if (_text(details.projectName) case final name?)
        PropertyFact(l10n.propertyProjectName, name),
      if (details.projectType != null)
        PropertyFact(l10n.propertyProjectType, value(details.projectType!)),
    ]),
    PropertyFactGroup(l10n.propertyFactsCosts, [
      if (details.maintenanceFee != null)
        PropertyFact(
          l10n.propertyMaintenanceFee,
          l10n.propertyFactPerMonth(
            PropertyFormat.money(details.maintenanceFee!),
          ),
        ),
      if (details.monthlyRent != null)
        PropertyFact(
          l10n.propertyMonthlyRent,
          l10n.propertyFactPerMonth(PropertyFormat.money(details.monthlyRent!)),
        ),
      if (details.leaseRemainingMonths != null)
        PropertyFact(
          l10n.propertyLeaseRemaining,
          l10n.propertyFactMonths(details.leaseRemainingMonths!),
        ),
      if (_text(details.equipmentIncluded) case final equipment?)
        PropertyFact(l10n.propertyEquipmentIncluded, equipment),
      if (_text(details.reasonForSelling) case final reason?)
        PropertyFact(l10n.propertyReasonForSelling, reason),
    ]),
  ];

  return [
    for (final group in groups)
      if (group.facts.isNotEmpty) group,
  ];
}

/// The price over the size cards show; null when either is unknown, or for
/// a rental, whose price is per month.
double? _pricePerSquareMetre(PropertyModel property) {
  if (property.isRental) return null;
  final size = property.displaySize;
  final price = property.finalPrice;
  if (size == null || price <= 0) return null;
  return price / size;
}

double? _positive(double? size) => size != null && size > 0 ? size : null;

String? _text(String? raw) {
  final text = raw?.trim();
  return text == null || text.isEmpty ? null : text;
}

/// A condo with no bedroom is a studio, as its form offers.
String _bedrooms(AppLocalizations l10n, PropertyModel property) {
  if (property.bedrooms == 0 && property.propertyType == 'Condo') {
    return l10n.propertyOptionStudio;
  }
  return '${property.bedrooms}';
}

/// What the form called the floors: of the tower for a condo, of the whole
/// building for a building.
String _floorsLabel(AppLocalizations l10n, PropertyModel property) {
  return switch (property.propertyType) {
    'Condo' => l10n.propertyTotalFloors,
    'Building' => l10n.propertyNumberOfFloors,
    _ => l10n.propertyFloors,
  };
}
