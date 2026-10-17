/// A feature a listing can be tagged with. [code] is what the server stores
/// (its `keywords` table); the label is only for display.
class PropertyKeyword {
  final String code;
  final String label;
  final String iconPath;

  const PropertyKeyword(this.code, this.label, this.iconPath);

  static const all = [
    PropertyKeyword(
      'road_access',
      'Road Access',
      'assets/icons/keyword_road_access.svg',
    ),
    PropertyKeyword(
      'corner_land',
      'Corner Land',
      'assets/icons/keyword_corner_land.svg',
    ),
    PropertyKeyword(
      'near_market',
      'Near Market',
      'assets/icons/keyword_near_market.svg',
    ),
    PropertyKeyword(
      'near_school',
      'Near School',
      'assets/icons/keyword_near_school.svg',
    ),
    PropertyKeyword(
      'near_hospital',
      'Near Hospital',
      'assets/icons/keyword_near_hospital.svg',
    ),
    PropertyKeyword(
      'river_lake_nearby',
      'River / Lake Nearby',
      'assets/icons/keyword_river_lake.svg',
    ),
    PropertyKeyword(
      'electricity_ready',
      'Electricity Ready',
      'assets/icons/keyword_electricity_ready.svg',
    ),
    PropertyKeyword(
      'water_supply',
      'Water Supply',
      'assets/icons/keyword_water_supply.svg',
    ),
    PropertyKeyword(
      'residential_area',
      'Residential Area',
      'assets/icons/keyword_residential_area.svg',
    ),
    PropertyKeyword(
      'commercial_area',
      'Commercial Area',
      'assets/icons/keyword_commercial_area.svg',
    ),
  ];
}
