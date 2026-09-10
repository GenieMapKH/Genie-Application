import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/presentation/view_models/property_providers.dart';

/// Everything the map needs to render property layers: one deduplicated list
/// plus the ids the signed-in user owns (owned properties get an edit marker).
class MapProperties {
  final List<PropertyModel> properties;
  final Set<String> ownedIds;

  const MapProperties({this.properties = const [], this.ownedIds = const {}});

  bool isOwned(String id) => ownedIds.contains(id);
}

/// Merges the user's own properties over the public map feed. The user's copy
/// wins on conflict because it carries fields the public endpoint may omit.
final mapPropertiesProvider = Provider<MapProperties>((ref) {
  final mine = ref.watch(propertiesProvider);
  final public = ref.watch(publicPropertiesProvider);

  final Map<String, PropertyModel> merged = {};
  final Set<String> ownedIds = {};

  if (public.hasValue) {
    for (final property in public.value!) {
      merged[property.id] = property;
    }
  }

  if (mine.hasValue) {
    for (final property in mine.value!) {
      merged[property.id] = property;
      ownedIds.add(property.id);
    }
  }

  return MapProperties(
    properties: merged.values.toList(),
    ownedIds: ownedIds,
  );
});
