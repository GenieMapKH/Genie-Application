import 'package:tilomnov/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tilomnov/features/property/data/repositories/property_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/features/property/data/models/nearby_place.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_providers.dart';

/// The full listing (the map's list leaves out details such as nearby
/// places), fetched when its detail sheet opens.
final propertyDetailProvider = FutureProvider.autoDispose
    .family<PropertyModel, String>((ref, id) async {
      final repository = ref.read(propertyRepositoryProvider);
      final admin = AuthStorage.isAdminAccessToken(
        await AuthStorage.getAccessToken(),
      );
      return admin
          ? PropertyRepository(
              repository.dio,
              admin: true,
            ).fetchPropertyDetail(id)
          : repository.fetchPropertyDetail(id);
    });

/// One category the listing is tagged near, with what was found.
class NearbyGroup {
  /// 'market', 'hospital' or 'school'.
  final String category;

  /// Closest first; empty when nothing is within the search radius.
  final List<NearbyPlace> places;

  const NearbyGroup(this.category, this.places);
}

/// The categories [property] is tagged near, in display order. Empty when it
/// has none of those keywords, or before the server has looked them up.
List<NearbyGroup> nearbyGroupsOf(PropertyModel property) {
  if (property.nearbySearchedAt == null) return const [];
  return [
    for (final MapEntry(key: category, value: keyword)
        in NearbyPlace.keywordByCategory.entries)
      if (property.keywords.contains(keyword))
        NearbyGroup(
          category,
          [
            for (final place in property.nearbyPlaces)
              if (place.category == category) place,
          ]..sort((a, b) => a.rank.compareTo(b.rank)),
        ),
  ];
}
