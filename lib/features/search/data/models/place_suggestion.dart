/// One suggested place (road, village, district, landmark), as a map app
/// lists them while you type.
class PlaceSuggestion {
  final String placeId;

  /// "Veng Sreng Blvd"
  final String primaryText;

  /// "Phnom Penh, Cambodia"
  final String? secondaryText;

  const PlaceSuggestion({
    required this.placeId,
    required this.primaryText,
    this.secondaryText,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestion(
      placeId: json['placeId'] as String,
      primaryText: json['primaryText'] as String,
      secondaryText: json['secondaryText'] as String?,
    );
  }
}
