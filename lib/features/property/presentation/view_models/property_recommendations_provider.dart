import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/features/home/presentation/providers/map_properties_provider.dart';
import 'package:genie/features/home/presentation/providers/property_carousel_provider.dart';
import 'package:genie/features/property/data/models/property_model.dart';

/// The two recommendation lists shown at the bottom of the detail sheet.
class PropertyRecommendations {
  /// Same property type as the one being viewed.
  final List<PropertyModel> similar;

  /// Everything else, as a general "you might also like" list.
  final List<PropertyModel> forYou;

  const PropertyRecommendations({
    this.similar = const [],
    this.forYou = const [],
  });
}

/// Recommendations for [propertyId], drawn from the properties already loaded
/// for the map so the sheet needs no extra network round trip.
final propertyRecommendationsProvider =
    Provider.family<PropertyRecommendations, String>((ref, propertyId) {
      final all = ref.watch(mapPropertiesProvider).properties;
      final source = all.firstWhere(
        (p) => p.id == propertyId,
        orElse: () => all.isEmpty ? _missing : all.first,
      );

      final candidates = all.where((p) => p.id != propertyId).toList();
      final origin = PropertyCarouselNotifier.centerOf(source);

      // Nearest first when we know where the viewed property is.
      if (origin != null) {
        candidates.sort((a, b) {
          final ca = PropertyCarouselNotifier.centerOf(a);
          final cb = PropertyCarouselNotifier.centerOf(b);
          if (ca == null) return 1;
          if (cb == null) return -1;
          final da =
              (ca.latitude - origin.latitude).abs() +
              (ca.longitude - origin.longitude).abs();
          final db =
              (cb.latitude - origin.latitude).abs() +
              (cb.longitude - origin.longitude).abs();
          return da.compareTo(db);
        });
      }

      final similar = candidates
          .where((p) => p.propertyType == source.propertyType)
          .take(2)
          .toList();
      final similarIds = similar.map((p) => p.id).toSet();
      final forYou = candidates
          .where((p) => !similarIds.contains(p.id))
          .take(2)
          .toList();

      return PropertyRecommendations(similar: similar, forYou: forYou);
    });

/// Sentinel used only when the property list is empty, so `firstWhere` has a
/// non-null fallback; both recommendation lists end up empty in that case.
final PropertyModel _missing = PropertyModel(
  id: '',
  title: '',
  price: '0',
  propertyType: '',
  status: 'Active',
  createdAt: DateTime(2000),
);
