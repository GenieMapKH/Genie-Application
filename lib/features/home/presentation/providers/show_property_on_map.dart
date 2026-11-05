import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/features/home/presentation/providers/main_nav_provider.dart';
import 'package:tilomnov/features/home/presentation/providers/property_carousel_provider.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/search/presentation/view_models/search_area_controller.dart';

/// Whether [property] has a place the map can show it at.
bool canShowPropertyOnMap(PropertyModel property) =>
    PropertyCarouselNotifier.centerOf(property) != null;

/// "View on map": leaves whatever page is open for the Explore map, framed on
/// [property] with its card up, as if its marker had been tapped.
void showPropertyOnMap(
  BuildContext context,
  WidgetRef ref,
  PropertyModel property,
) {
  Navigator.of(context).popUntil((route) => route.isFirst);
  // A searched place or person would frame the map elsewhere.
  ref.read(searchAreaControllerProvider.notifier).clear();
  ref.read(mainNavProvider.notifier).resetToHome();
  ref.read(propertyCarouselProvider.notifier).select(property);
}
