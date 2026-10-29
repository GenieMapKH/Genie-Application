import 'package:tilomnov/features/property/data/models/property_model.dart';

/// A published listing and how far it is from where the list was asked
/// from (the user, or the map's centre).
class ClosestListing {
  final PropertyModel property;
  final int distanceMeters;

  const ClosestListing({required this.property, required this.distanceMeters});

  factory ClosestListing.fromJson(Map<String, dynamic> json) => ClosestListing(
    property: PropertyModel.fromJson(json),
    distanceMeters: (json['distanceMeters'] as num?)?.round() ?? 0,
  );

  static List<ClosestListing> listFromJson(List<dynamic> data) => [
    for (final item in data)
      ClosestListing.fromJson(item as Map<String, dynamic>),
  ];
}
