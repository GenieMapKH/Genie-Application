import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/search/data/models/place_suggestion.dart';
import 'package:genie/features/search/data/models/publisher_summary.dart';

/// What the map should show after a search: a place or a person, each with
/// the listings that belong to it.
sealed class SearchTarget {
  const SearchTarget();

  /// What the search bar and the panel heading show.
  String get title;
}

class PlaceTarget extends SearchTarget {
  final PlaceSuggestion place;

  /// The token of the search that suggested [place]: the lookup closes that
  /// billed session with the map provider.
  final String sessionToken;
  final String language;

  const PlaceTarget(
    this.place, {
    required this.sessionToken,
    required this.language,
  });

  @override
  String get title => place.primaryText;
}

class PersonTarget extends SearchTarget {
  final PublisherSummary person;

  const PersonTarget(this.person);

  @override
  String get title => person.displayName;
}

/// What the search page hands back when the user picks a result.
sealed class SearchSelection {
  const SearchSelection();
}

/// A place or a person: shown on the map with their listings.
class AreaSelection extends SearchSelection {
  final SearchTarget target;

  const AreaSelection(this.target);
}

/// One listing: opened straight away, like a tap on the map.
class PropertySelection extends SearchSelection {
  final PropertyModel property;

  const PropertySelection(this.property);
}
