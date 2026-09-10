import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:genie/features/home/presentation/providers/map_properties_provider.dart';
import 'package:genie/features/property/data/models/property_model.dart';

/// State backing the horizontal card carousel above the bottom nav.
///
/// [items] is ordered by distance from the property the user first tapped, so
/// swiping left/right walks outward to progressively further neighbours. The
/// list is only rebuilt when a *new* anchor is tapped — swiping keeps the same
/// list so cards don't reshuffle underneath the user's finger.
class PropertyCarouselState {
  final List<PropertyModel> items;
  final int index;

  const PropertyCarouselState({this.items = const [], this.index = 0});

  bool get isVisible => items.isNotEmpty;

  PropertyModel? get selected =>
      index >= 0 && index < items.length ? items[index] : null;
}

class PropertyCarouselNotifier extends Notifier<PropertyCarouselState> {
  /// How many neighbours to keep alongside the anchor. Bounded so the PageView
  /// stays cheap on dense maps.
  static const int _maxItems = 30;

  @override
  PropertyCarouselState build() {
    // Drop a stale selection if the underlying property disappears (deleted,
    // unpublished, or filtered out of the map feed).
    ref.listen(mapPropertiesProvider, (previous, next) {
      final current = state.selected;
      if (current == null) return;
      final stillExists = next.properties.any((p) => p.id == current.id);
      if (!stillExists) state = const PropertyCarouselState();
    });

    return const PropertyCarouselState();
  }

  /// Called when a marker or polygon is tapped. If the property is already in
  /// the current list we just move the index, preserving swipe context.
  void select(PropertyModel property) {
    final existing = state.items.indexWhere((p) => p.id == property.id);
    if (existing != -1) {
      if (existing != state.index) {
        state = PropertyCarouselState(items: state.items, index: existing);
      }
      return;
    }

    state = PropertyCarouselState(items: _nearbyFrom(property), index: 0);
  }

  /// Called when the user swipes the PageView to a different card.
  void setIndex(int index) {
    if (index < 0 || index >= state.items.length || index == state.index) return;
    state = PropertyCarouselState(items: state.items, index: index);
  }

  void clear() {
    if (state.items.isEmpty) return;
    state = const PropertyCarouselState();
  }

  /// Anchor first, then every other locatable property sorted by distance.
  List<PropertyModel> _nearbyFrom(PropertyModel anchor) {
    final origin = centerOf(anchor);
    if (origin == null) return [anchor];

    final others = ref
        .read(mapPropertiesProvider)
        .properties
        .where((p) => p.id != anchor.id && centerOf(p) != null)
        .toList();

    others.sort((a, b) {
      final da = _squaredDistance(origin, centerOf(a)!);
      final db = _squaredDistance(origin, centerOf(b)!);
      return da.compareTo(db);
    });

    return [anchor, ...others.take(_maxItems - 1)];
  }

  /// Cheap planar comparison — adequate for ranking nearby listings and far
  /// faster than a full haversine over every property on every tap.
  static double _squaredDistance(LatLng a, LatLng b) {
    final dLat = a.latitude - b.latitude;
    // Scale longitude by cos(lat) so east-west distance isn't overstated.
    final dLng =
        (a.longitude - b.longitude) * math.cos(a.latitude * math.pi / 180);
    return dLat * dLat + dLng * dLng;
  }

  /// A property's map position: the boundary centroid, or its pin if it has no
  /// drawn boundary.
  static LatLng? centerOf(PropertyModel property) {
    if (property.boundaryPoints.length >= 3) {
      double sumLat = 0, sumLng = 0;
      for (final point in property.boundaryPoints) {
        sumLat += point.latitude;
        sumLng += point.longitude;
      }
      final count = property.boundaryPoints.length;
      return LatLng(sumLat / count, sumLng / count);
    }
    if (property.lat != null && property.lng != null) {
      return LatLng(property.lat!, property.lng!);
    }
    return null;
  }
}

final propertyCarouselProvider =
    NotifierProvider<PropertyCarouselNotifier, PropertyCarouselState>(
      PropertyCarouselNotifier.new,
    );
