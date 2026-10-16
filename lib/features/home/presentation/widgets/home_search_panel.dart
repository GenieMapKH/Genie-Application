import 'package:flutter/material.dart';

import 'package:genie/features/home/presentation/widgets/main_map_controls.dart';
import 'package:genie/features/home/presentation/widgets/map_top_controls.dart';
import 'package:genie/features/home/presentation/widgets/property_carousel.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/search/presentation/search_layout.dart';
import 'package:genie/features/search/presentation/widgets/area/search_area_panel.dart';

/// Places the search results panel on the home map, between the search bar
/// and the navigation bar.
///
/// The map stack holds it twice, on each side of the map controls: on phones
/// the sheet is dragged up over the controls, so it draws above them; on wide
/// screens the side panel sits under them, so the add menu opens over it.
class HomeSearchPanel extends StatelessWidget {
  final bool aboveControls;
  final bool visible;
  final ValueChanged<PropertyModel> onOpenProperty;

  const HomeSearchPanel({
    super.key,
    required this.aboveControls,
    required this.visible,
    required this.onOpenProperty,
  });

  /// Space around the panel: under the search bar, above the navigation bar
  /// (and, beside the map, above the floating buttons).
  static EdgeInsets margin(BuildContext context) {
    final top =
        MediaQuery.paddingOf(context).top + MapTopControls.contentHeight;
    if (SearchLayout.isWide(MediaQuery.sizeOf(context).width)) {
      return EdgeInsets.only(
        left: 16,
        top: top,
        bottom: MainMapControls.baseBottom + MainMapControls.buttonSize,
      );
    }
    return EdgeInsets.only(
      top: top,
      bottom: PropertyCarousel.bottomNavHeight - 8,
    );
  }

  /// Everything that hides the map while the panel rests: the search bar,
  /// the panel and the navigation bar. The camera frames a search inside
  /// what is left.
  static EdgeInsets coveredInsets(BuildContext context) {
    final margin = HomeSearchPanel.margin(context);
    final panel = SearchAreaPanel.coveredInsets(
      MediaQuery.sizeOf(context),
      margin,
    );
    return EdgeInsets.only(
      top: margin.top,
      left: panel.left,
      bottom: panel.bottom > 0
          ? panel.bottom
          : PropertyCarousel.bottomNavHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = SearchLayout.isWide(MediaQuery.sizeOf(context).width);
    if (!visible || aboveControls == wide) return const SizedBox.shrink();

    return SearchAreaPanel(
      margin: margin(context),
      onOpenProperty: onOpenProperty,
    );
  }
}
