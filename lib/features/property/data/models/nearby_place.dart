/// A market, hospital or school near a listing, found by the server when the
/// listing was placed with the matching "near ..." keyword.
class NearbyPlace {
  /// 'market', 'hospital' or 'school'.
  final String category;

  /// 0 is the closest by road.
  final int rank;
  final String name;
  final double lat;
  final double lng;
  final int straightMeters;

  /// Null when no road to it was found.
  final int? roadMeters;

  const NearbyPlace({
    required this.category,
    required this.rank,
    required this.name,
    required this.lat,
    required this.lng,
    required this.straightMeters,
    this.roadMeters,
  });

  factory NearbyPlace.fromJson(Map<String, dynamic> json) => NearbyPlace(
    category: json['category'] as String,
    rank: json['rank'] as int,
    name: json['name'] as String,
    lat: (json['lat'] as num).toDouble(),
    lng: (json['lng'] as num).toDouble(),
    straightMeters: json['straightMeters'] as int,
    roadMeters: json['roadMeters'] as int?,
  );

  /// The categories, in display order, with the keyword that asks for each.
  static const keywordByCategory = {
    'market': 'near_market',
    'hospital': 'near_hospital',
    'school': 'near_school',
  };

  /// How far around a listing the server looks, in km.
  static const searchRadiusKm = 5;
}
