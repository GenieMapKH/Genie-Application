import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/search/presentation/search_layout.dart';
import 'package:tilomnov/features/search/presentation/view_models/search_area_controller.dart';
import 'package:tilomnov/features/search/presentation/view_models/search_selection.dart';
import 'package:tilomnov/features/search/presentation/widgets/area/search_area_header.dart';
import 'package:tilomnov/features/search/presentation/widgets/area/search_area_listings.dart';
import 'package:tilomnov/features/search/presentation/widgets/area/search_area_sheet.dart';
import 'package:tilomnov/features/search/presentation/widgets/area/search_area_slide_up.dart';

/// The listings of the place or person the map shows after a search. On
/// phones a sheet that can be dragged up over the map; on wide screens a
/// panel beside it. Draws nothing while no search is shown.
///
/// Fill the map's stack with it: [margin] keeps it clear of the controls
/// above it and the navigation bar below it.
class SearchAreaPanel extends ConsumerWidget {
  final EdgeInsets margin;
  final ValueChanged<PropertyModel> onOpenProperty;

  /// Size of the floating glass navigation capsule, when the glass bar is
  /// on and [margin] ends at the capsule's bottom edge. The phone sheet is
  /// then as wide as the capsule and centred on it, its foot behind it, the
  /// way the pull-up list of listings near the user grows out of it.
  final Size? glassNav;

  const SearchAreaPanel({
    super.key,
    required this.margin,
    required this.onOpenProperty,
    this.glassNav,
  });

  /// The part of a [screen]-sized map the panel covers while resting, so the
  /// camera can frame the area in what stays visible. [foot] is the height
  /// of the sheet hidden behind the glass nav capsule. While [focused] on a
  /// listing, the phone sheet is collapsed to show the map.
  static EdgeInsets coveredInsets(
    Size screen,
    EdgeInsets margin, {
    double foot = 0,
    bool focused = false,
  }) {
    if (SearchLayout.isWide(screen.width)) {
      return EdgeInsets.only(
        left: margin.left + SearchLayout.sidePanelWidth(screen.width),
      );
    }
    if (focused) {
      return EdgeInsets.only(
        bottom:
            margin.bottom +
            foot +
            SearchAreaSheet.collapsedHeight(focused: true),
      );
    }
    final available = screen.height - margin.vertical - foot;
    return EdgeInsets.only(
      bottom: margin.bottom + foot + SearchLayout.sheetRestingHeight(available),
    );
  }

  static bool _hasLocation(PropertyModel property) =>
      property.boundaryPoints.length >= 3 ||
      (property.lat != null && property.lng != null);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchAreaControllerProvider);
    if (state == null) return const SizedBox.shrink();

    final controller = ref.read(searchAreaControllerProvider.notifier);
    final header = SearchAreaHeader(state: state, onClose: controller.clear);
    final screen = MediaQuery.sizeOf(context);
    final width = screen.width;
    // A person's listing is first shown on the map, its detail opened from
    // its "View property" button.
    final showOnMapFirst = state.target is PersonTarget;
    final listings = SearchAreaListings(
      state: state,
      height: screen.height - margin.vertical,
      onTapProperty: (property) =>
          showOnMapFirst &&
              property.id != state.focused?.id &&
              _hasLocation(property)
          ? controller.focus(property)
          : onOpenProperty(property),
      onOpenProperty: onOpenProperty,
      onRetry: controller.retry,
    );

    // A new place or person slides in afresh.
    final key = ObjectKey(state.target);
    return SearchLayout.isWide(width)
        ? _SidePanel(
            key: key,
            margin: margin,
            width: SearchLayout.sidePanelWidth(width),
            header: header,
            listings: listings,
          )
        : SearchAreaSheet(
            key: key,
            margin: margin,
            glassNav: glassNav,
            header: header,
            focused: state.focused,
            onOpenProperty: onOpenProperty,
            listings: listings,
          );
  }
}

class _SidePanel extends StatelessWidget {
  final EdgeInsets margin;
  final double width;
  final Widget header;
  final Widget listings;

  const _SidePanel({
    super.key,
    required this.margin,
    required this.width,
    required this.header,
    required this.listings,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Positioned(
      left: margin.left,
      top: margin.top,
      bottom: margin.bottom,
      width: width,
      child: SearchAreaSlideUp(
        child: Material(
          color: colors.surface,
          elevation: 6,
          shadowColor: Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              header,
              Divider(height: 1, color: colors.divider),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    listings,
                    const SliverPadding(padding: EdgeInsets.only(bottom: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
