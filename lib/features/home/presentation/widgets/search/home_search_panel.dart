import 'package:flutter/material.dart';

import 'package:tilomnov/features/home/presentation/widgets/layout/glass_bottom_nav.dart';
import 'package:tilomnov/features/home/presentation/widgets/map/main_map_controls.dart';
import 'package:tilomnov/features/home/presentation/widgets/map/map_top_controls.dart';
import 'package:tilomnov/features/home/presentation/widgets/map/property_carousel.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/search/presentation/search_layout.dart';
import 'package:tilomnov/features/search/presentation/widgets/area/search_area_panel.dart';

/// Places the search results panel on the home map, between the search bar
/// and the navigation bar.
///
/// The map stack holds it twice, on each side of the map controls: on phones
/// the sheet is dragged up over the controls, so it draws above them; on wide
/// screens the side panel sits under them, so the add menu opens over it.
class HomeSearchPanel extends StatelessWidget {
  final bool aboveControls;
  final bool visible;

  /// Whether the bottom navigation is the floating glass capsule: the phone
  /// sheet then grows out of it, like the pull-up list of listings near the
  /// user.
  final bool glassNav;
  final ValueChanged<PropertyModel> onOpenProperty;

  const HomeSearchPanel({
    super.key,
    required this.aboveControls,
    required this.visible,
    required this.glassNav,
    required this.onOpenProperty,
  });

  /// Space around the panel: under the search bar, above the navigation bar
  /// (and, beside the map, above the floating buttons). With the glass bar
  /// the phone sheet ends at the capsule's bottom edge, its foot behind it.
  static EdgeInsets margin(BuildContext context, {required bool glassNav}) {
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
      bottom: glassNav
          ? GlassBottomNav.capsuleBottomOf(context)
          : PropertyCarousel.bottomNavHeight - 8,
    );
  }

  /// The glass capsule the phone sheet grows out of, if any.
  static Size? _capsule(BuildContext context, {required bool glassNav}) {
    final width = MediaQuery.sizeOf(context).width;
    return glassNav && !SearchLayout.isWide(width)
        ? GlassBottomNav.capsuleSizeFor(width)
        : null;
  }

  /// Everything that hides the map while the panel rests: the search bar,
  /// the panel and the navigation bar. The camera frames a search inside
  /// what is left. While [focused] on a listing, the phone sheet is
  /// collapsed to show the map.
  static EdgeInsets coveredInsets(
    BuildContext context, {
    required bool glassNav,
    bool focused = false,
  }) {
    final margin = HomeSearchPanel.margin(context, glassNav: glassNav);
    final panel = SearchAreaPanel.coveredInsets(
      MediaQuery.sizeOf(context),
      margin,
      foot: _capsule(context, glassNav: glassNav)?.height ?? 0,
      focused: focused,
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
      margin: margin(context, glassNav: glassNav),
      glassNav: _capsule(context, glassNav: glassNav),
      onOpenProperty: onOpenProperty,
    );
  }
}
