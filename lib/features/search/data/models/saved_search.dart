import 'package:genie/features/property/data/models/map_property_filter.dart';
import 'package:genie/features/property/presentation/view_models/property_providers.dart';

/// A map area and filter the user saved, alerting them (when [alerts] is
/// on) about new listings it would show.
class SavedSearch {
  final String id;
  final String name;
  final MapBounds area;
  final MapPropertyFilter filter;
  final bool alerts;

  const SavedSearch({
    required this.id,
    required this.name,
    required this.area,
    required this.filter,
    required this.alerts,
  });

  factory SavedSearch.fromJson(Map<String, dynamic> json) {
    double? number(String key) => (json[key] as num?)?.toDouble();
    List<String> strings(String key) =>
        (json[key] as List? ?? const []).cast<String>();
    return SavedSearch(
      id: json['id'] as String,
      name: json['name'] as String,
      area: MapBounds(
        minLat: number('minLat')!,
        maxLat: number('maxLat')!,
        minLng: number('minLng')!,
        maxLng: number('maxLng')!,
      ),
      filter: MapPropertyFilter(
        propertyType: json['propertyType'] as String?,
        listingTypes: strings('listingTypes'),
        minPrice: number('minPrice'),
        maxPrice: number('maxPrice'),
        minSize: number('minSize'),
        maxSize: number('maxSize'),
        keywords: strings('keywords').toSet(),
      ),
      alerts: json['alerts'] as bool? ?? true,
    );
  }

  /// What `POST /search/saved` takes for [area] and [filter] named [name].
  static Map<String, Object> requestBody({
    required String name,
    required MapBounds area,
    required MapPropertyFilter filter,
  }) => {
    'name': name,
    'minLat': area.minLat,
    'maxLat': area.maxLat,
    'minLng': area.minLng,
    'maxLng': area.maxLng,
    'propertyType': ?filter.propertyType,
    if (filter.listingTypes.isNotEmpty) 'listingTypes': filter.listingTypes,
    'minPrice': ?filter.minPrice,
    'maxPrice': ?filter.maxPrice,
    'minSize': ?filter.minSize,
    'maxSize': ?filter.maxSize,
    if (filter.keywords.isNotEmpty)
      'keywords': (filter.keywords.toList()..sort()),
  };

  SavedSearch copyWith({String? name, bool? alerts}) => SavedSearch(
    id: id,
    name: name ?? this.name,
    area: area,
    filter: filter,
    alerts: alerts ?? this.alerts,
  );
}
