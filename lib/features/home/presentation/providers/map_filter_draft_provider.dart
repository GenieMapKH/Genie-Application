import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/features/property/presentation/view_models/map_property_filter.dart';
import 'package:genie/features/property/presentation/view_models/property_providers.dart';

/// The span of the filter page's price slider: sale prices, or monthly rents.
class MapPriceScale {
  /// The slider's top; it means "this and more".
  final double top;

  /// What one slider notch moves the price by.
  final double step;

  final bool perMonth;

  const MapPriceScale._(this.top, this.step, {this.perMonth = false});

  static const sale = MapPriceScale._(500000, 5000);
  static const rent = MapPriceScale._(5000, 50, perMonth: true);

  static MapPriceScale of(MapPropertyFilter filter) =>
      filter.isForRent ? rent : sale;

  int get divisions => (top / step).round();
}

/// The filter page's choices, kept apart from the map until "See results".
class MapFilterDraftNotifier extends AutoDisposeNotifier<MapPropertyFilter> {
  @override
  MapPropertyFilter build() {
    final shown = ref.read(mapPropertyFilterProvider);
    // The page always has a tab lit: "For sale" unless the map already
    // narrows to something else.
    return shown.listingTypes.isEmpty
        ? shown.withListingTypes(MapPropertyFilter.forSale)
        : shown;
  }

  /// The tabs choose between scales, so the price range starts over.
  void selectListing(List<String> types) {
    if (MapPropertyFilter.listingEquals(state.listingTypes, types)) return;
    state = state.withListingTypes(types).withPrice(null, null);
  }

  void setPrice(double? min, double? max) => state = state.withPrice(min, max);

  void setSize(double? min, double? max) => state = state.withSize(min, max);

  void toggleType(String type) => state = state.toggleType(type);

  void toggleKeyword(String code) => state = state.toggleKeyword(code);

  /// Clears every choice but the For sale / For rent tab.
  void reset() => state = MapPropertyFilter(listingTypes: state.listingTypes);

  /// Puts the draft on the map. False, changing nothing, while a range is
  /// upside down.
  bool apply() {
    if (!isValid(state)) return false;
    ref.read(mapPropertyFilterProvider.notifier).state = state;
    return true;
  }

  static bool priceRangeInvalid(MapPropertyFilter f) =>
      f.minPrice != null && f.maxPrice != null && f.minPrice! > f.maxPrice!;

  static bool sizeRangeInvalid(MapPropertyFilter f) =>
      f.minSize != null && f.maxSize != null && f.minSize! > f.maxSize!;

  static bool isValid(MapPropertyFilter f) =>
      !priceRangeInvalid(f) && !sizeRangeInvalid(f);
}

final mapFilterDraftProvider =
    AutoDisposeNotifierProvider<MapFilterDraftNotifier, MapPropertyFilter>(
      MapFilterDraftNotifier.new,
    );

/// The bars behind the price slider for the area on the map and the draft
/// (its price range left out: the bars show every price the rest allows).
/// Empty before the map knows its area.
final mapPriceHistogramProvider = FutureProvider.autoDispose
    .family<List<int>, MapPropertyFilter>((ref, unpriced) async {
      final bounds = ref.read(mapBoundsProvider);
      if (bounds == null) return const [];
      final box = bounds.widenedToGrid();
      return ref
          .read(propertyRepositoryProvider)
          .fetchMapPriceHistogram(
            minLat: box.minLat,
            maxLat: box.maxLat,
            minLng: box.minLng,
            maxLng: box.maxLng,
            filter: unpriced,
            upTo: MapPriceScale.of(unpriced).top,
          );
    });
