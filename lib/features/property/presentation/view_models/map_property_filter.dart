import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/features/property/data/models/map_property_filter.dart';

export 'package:genie/features/property/data/models/map_property_filter.dart';

/// The filter the map obeys, set by the pills under the search bar and by
/// the filter page.
final mapPropertyFilterProvider = StateProvider<MapPropertyFilter>(
  (ref) => const MapPropertyFilter(),
);
