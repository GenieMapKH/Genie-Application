/// What the add-property form asks beyond the basics. Which of these a
/// listing has depends on its type; the server clears the others.
class PropertyDetails {
  final String? titleType;
  final String? contactPhone;

  /// Floors of a house or building; total floors of the tower for a condo.
  final int? floors;

  /// The floor a condo unit is on.
  final int? floorNumber;
  final int? totalUnits;
  final bool? hasParking;
  final bool? hasBalcony;
  final String? furnishing;
  final String? buildingType;
  final String? completionStatus;
  final String? viewType;
  final double? maintenanceFee;
  final String? developerName;
  final String? projectName;
  final String? projectType;
  final double? totalProjectArea;
  final double? monthlyRent;
  final int? leaseRemainingMonths;
  final String? equipmentIncluded;
  final String? reasonForSelling;

  const PropertyDetails({
    this.titleType,
    this.contactPhone,
    this.floors,
    this.floorNumber,
    this.totalUnits,
    this.hasParking,
    this.hasBalcony,
    this.furnishing,
    this.buildingType,
    this.completionStatus,
    this.viewType,
    this.maintenanceFee,
    this.developerName,
    this.projectName,
    this.projectType,
    this.totalProjectArea,
    this.monthlyRent,
    this.leaseRemainingMonths,
    this.equipmentIncluded,
    this.reasonForSelling,
  });

  /// Reads the details from a property response, where they sit next to the
  /// basics. Decimals arrive as strings.
  factory PropertyDetails.fromJson(Map<String, dynamic> json) {
    double? decimal(String key) {
      final value = json[key];
      return value == null ? null : double.tryParse(value.toString());
    }

    return PropertyDetails(
      titleType: json['titleType'] as String?,
      contactPhone: json['contactPhone'] as String?,
      floors: json['floors'] as int?,
      floorNumber: json['floorNumber'] as int?,
      totalUnits: json['totalUnits'] as int?,
      hasParking: json['hasParking'] as bool?,
      hasBalcony: json['hasBalcony'] as bool?,
      furnishing: json['furnishing'] as String?,
      buildingType: json['buildingType'] as String?,
      completionStatus: json['completionStatus'] as String?,
      viewType: json['viewType'] as String?,
      maintenanceFee: decimal('maintenanceFee'),
      developerName: json['developerName'] as String?,
      projectName: json['projectName'] as String?,
      projectType: json['projectType'] as String?,
      totalProjectArea: decimal('totalProjectArea'),
      monthlyRent: decimal('monthlyRent'),
      leaseRemainingMonths: json['leaseRemainingMonths'] as int?,
      equipmentIncluded: json['equipmentIncluded'] as String?,
      reasonForSelling: json['reasonForSelling'] as String?,
    );
  }
}
