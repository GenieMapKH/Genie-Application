import 'package:genie/features/property/data/models/property_model.dart';

/// Everything typed or picked on the add-property form, as the form holds
/// it (text and dropdown labels). Converts to the request body the server
/// takes and back from a saved listing, so editing opens the form as it was.
class PropertyFormInput {
  final String propertyType;
  final String title;
  final String price;
  final String listingType;
  final String titleType;
  final String landSize;
  final String buildingSize;
  final String unitSize;
  final String maintenanceFee;
  final String developerName;
  final String projectName;
  final String totalProjectArea;

  /// Typed for a Borey project; [totalUnits] is picked for a building.
  final String totalUnitsText;

  /// A Borey project's lowest unit price, stored as its price.
  final String startingPrice;
  final String monthlyRent;
  final String leaseRemaining;
  final String equipmentIncluded;
  final String reasonForSelling;
  final String description;
  final String contactPhone;

  /// Empty for no discount; [discountType] says how to read it.
  final String discount;

  /// 'percent' or 'amount' (USD off the price).
  final String discountType;

  final String? bedrooms;
  final String? bathrooms;
  final String? floors;
  final String? floorNumber;
  final String? parking;
  final String? furnished;
  final String? buildingType;
  final String? totalUnits;
  final String? balcony;
  final String? completionStatus;
  final String? viewType;
  final String? projectType;
  final String? leaseUnit;
  final Set<String> keywords;

  const PropertyFormInput({
    this.propertyType = 'Land',
    this.title = '',
    this.price = '',
    this.listingType = 'Sale',
    this.titleType = 'Hard Title',
    this.landSize = '',
    this.buildingSize = '',
    this.unitSize = '',
    this.maintenanceFee = '',
    this.developerName = '',
    this.projectName = '',
    this.totalProjectArea = '',
    this.totalUnitsText = '',
    this.startingPrice = '',
    this.monthlyRent = '',
    this.leaseRemaining = '',
    this.equipmentIncluded = '',
    this.reasonForSelling = '',
    this.description = '',
    this.contactPhone = '',
    this.discount = '',
    this.discountType = 'percent',
    this.bedrooms,
    this.bathrooms,
    this.floors,
    this.floorNumber,
    this.parking,
    this.furnished,
    this.buildingType,
    this.totalUnits,
    this.balcony,
    this.completionStatus,
    this.viewType,
    this.projectType,
    this.leaseUnit,
    this.keywords = const {},
  });

  /// The dropdowns' "or more" choice, stored as its number.
  static const _orMore = '10+';
  static const _orMoreValue = 10;
  static const _studio = 'Studio';

  String get _type => propertyType.isEmpty ? 'Land' : propertyType;

  /// The body for `POST /properties` and `PATCH /properties/:id`. Empty
  /// fields are sent as null, so an edit can clear them; the server drops
  /// the details that do not belong to the type.
  Map<String, dynamic> toRequestBody() {
    final isBorey = _type == 'Borey';
    return {
      'title': title.trim().isEmpty ? 'Untitled Property' : title.trim(),
      'price': _decimal(isBorey ? startingPrice : price) ?? 0,
      'propertyType': _type,
      'discountType': _decimal(discount) == null ? null : discountType,
      'discountValue': _decimal(discount),
      'listingType': listingType.isEmpty ? null : listingType,
      'titleType': titleType.isEmpty ? null : titleType,
      'description': _text(description),
      'contactPhone': _text(contactPhone),
      'landSize': _decimal(landSize),
      'buildingSize': _decimal(buildingSize),
      'unitSize': _decimal(unitSize),
      'totalProjectArea': _decimal(totalProjectArea),
      'maintenanceFee': _decimal(maintenanceFee),
      'monthlyRent': _decimal(monthlyRent),
      'bedrooms': _count(bedrooms),
      'bathrooms': _count(bathrooms),
      'floors': _count(floors),
      'floorNumber': _count(floorNumber),
      'totalUnits': isBorey ? _count(totalUnitsText) : _count(totalUnits),
      'hasParking': _yesNo(parking),
      'hasBalcony': _yesNo(balcony),
      'furnishing': furnished,
      'buildingType': buildingType,
      'completionStatus': completionStatus,
      'viewType': viewType,
      'projectType': projectType,
      'developerName': _text(developerName),
      'projectName': _text(projectName),
      'leaseRemainingMonths': _leaseMonths(),
      'equipmentIncluded': _text(equipmentIncluded),
      'reasonForSelling': _text(reasonForSelling),
      'keywords': keywords.toList()..sort(),
    };
  }

  /// The form as it was filled for [property].
  factory PropertyFormInput.fromProperty(PropertyModel property) {
    final details = property.details;
    final isBorey = property.propertyType == 'Borey';
    final isCondo = property.propertyType == 'Condo';
    final lease = details.leaseRemainingMonths;
    final leaseInYears = lease != null && lease > 0 && lease % 12 == 0;

    return PropertyFormInput(
      propertyType: property.propertyType,
      title: property.title,
      price: isBorey ? '' : _number(double.tryParse(property.price)),
      startingPrice: isBorey ? _number(double.tryParse(property.price)) : '',
      listingType: property.listingType ?? 'Sale',
      titleType: details.titleType ?? 'Hard Title',
      landSize: _number(property.landSize),
      buildingSize: _number(property.buildingSize),
      unitSize: _number(property.unitSize),
      maintenanceFee: _number(details.maintenanceFee),
      totalProjectArea: _number(details.totalProjectArea),
      monthlyRent: _number(details.monthlyRent),
      developerName: details.developerName ?? '',
      projectName: details.projectName ?? '',
      equipmentIncluded: details.equipmentIncluded ?? '',
      reasonForSelling: details.reasonForSelling ?? '',
      description: property.description ?? '',
      contactPhone: details.contactPhone ?? '',
      discount: _number(property.discountValue),
      discountType: property.discountType ?? 'percent',
      bedrooms: isCondo && property.bedrooms == 0
          ? _studio
          : _choice(property.bedrooms),
      bathrooms: _choice(property.bathrooms),
      floors: _choice(details.floors),
      floorNumber: _choice(details.floorNumber),
      totalUnits: isBorey ? null : _choice(details.totalUnits),
      totalUnitsText: isBorey ? details.totalUnits?.toString() ?? '' : '',
      parking: _yesNoLabel(details.hasParking),
      balcony: _yesNoLabel(details.hasBalcony),
      furnished: details.furnishing,
      buildingType: details.buildingType,
      completionStatus: details.completionStatus,
      viewType: details.viewType,
      projectType: details.projectType,
      leaseRemaining: lease == null
          ? ''
          : (leaseInYears ? lease ~/ 12 : lease).toString(),
      leaseUnit: lease == null ? null : (leaseInYears ? 'Years' : 'Months'),
      keywords: property.keywords.toSet(),
    );
  }

  int? _leaseMonths() {
    final amount = int.tryParse(leaseRemaining.trim());
    if (amount == null) return null;
    return leaseUnit == 'Years' ? amount * 12 : amount;
  }

  static String? _text(String value) =>
      value.trim().isEmpty ? null : value.trim();

  static double? _decimal(String value) =>
      double.tryParse(value.replaceAll(',', '').trim());

  static int? _count(String? choice) {
    if (choice == null) return null;
    if (choice == _orMore) return _orMoreValue;
    if (choice == _studio) return 0;
    return int.tryParse(choice.trim());
  }

  static bool? _yesNo(String? choice) => switch (choice) {
    'Yes' => true,
    'No' => false,
    _ => null,
  };

  static String? _yesNoLabel(bool? value) =>
      value == null ? null : (value ? 'Yes' : 'No');

  static String? _choice(int? count) {
    if (count == null) return null;
    return count >= _orMoreValue ? _orMore : count.toString();
  }

  /// 120000.0 -> "120000", 72.5 -> "72.5".
  static String _number(double? value) {
    if (value == null) return '';
    return value == value.truncateToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
  }
}
