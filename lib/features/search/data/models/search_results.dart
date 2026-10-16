import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/search/data/models/place_suggestion.dart';
import 'package:genie/features/search/data/models/publisher_summary.dart';

/// Everything one search text found: places first, as in a map app, then
/// published listings, then the people who post them.
class SearchResults {
  final List<PlaceSuggestion> places;
  final List<PropertyModel> properties;
  final List<PublisherSummary> people;

  const SearchResults({
    this.places = const [],
    this.properties = const [],
    this.people = const [],
  });

  static const empty = SearchResults();

  bool get isEmpty => places.isEmpty && properties.isEmpty && people.isEmpty;

  factory SearchResults.fromJson(Map<String, dynamic> json) {
    List<T> listOf<T>(String key, T Function(Map<String, dynamic>) parse) {
      final raw = json[key] as List<dynamic>? ?? const [];
      return raw.map((item) => parse(item as Map<String, dynamic>)).toList();
    }

    return SearchResults(
      places: listOf('places', PlaceSuggestion.fromJson),
      properties: listOf('properties', PropertyModel.fromJson),
      people: listOf('people', PublisherSummary.fromJson),
    );
  }
}
