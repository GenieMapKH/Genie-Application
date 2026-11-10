import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/closest_listings/presentation/closest_sheet_layout.dart';
import 'package:tilomnov/features/closest_listings/presentation/view_models/closest_listings_provider.dart';
import 'package:tilomnov/features/closest_listings/presentation/widgets/closest_glass_handle.dart';
import 'package:tilomnov/features/closest_listings/presentation/widgets/closest_listings_body.dart';
import 'package:tilomnov/features/closest_listings/presentation/widgets/closest_listings_header.dart';
import 'package:tilomnov/features/closest_listings/presentation/widgets/liquid_rise_border.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/shared/widgets/lists/load_more_on_scroll.dart';

/// What the pull-up list's sheet shows: its panel of listings, and with
/// the glass navigation bar the glass handle it is pulled out of.
///
/// With glass the panel is unseen while resting; pulled, it swells out of
/// the nav as a drop hanging from the handle ([LiquidRiseBorder]) and
/// widens into the whole panel, while the handle becomes its top edge
/// ([ClosestGlassHandle]), following the pull rather than a timed fade.
class ClosestSheetPanel extends StatelessWidget {
  final ScrollController scrollController;
  final double width;
  final double height;
  final bool docked;
  final bool glass;

  /// Height of the panel's foot hidden behind the glass nav capsule, 0 when
  /// the panel ends above the nav.
  final double footHeight;

  /// Pulled up at least once: the list is read from then on.
  final ValueListenable<bool> opened;

  /// How far the drop has become the panel, 0 to 1. Only used with
  /// [glass].
  final ValueListenable<double> rise;

  final VoidCallback onHandleTap;
  final ValueChanged<PropertyModel> onOpen;

  const ClosestSheetPanel({
    super.key,
    required this.scrollController,
    required this.width,
    required this.height,
    required this.docked,
    required this.glass,
    this.footHeight = 0,
    required this.opened,
    required this.rise,
    required this.onHandleTap,
    required this.onOpen,
  });

  static const _radius = 22.0;

  @override
  Widget build(BuildContext context) {
    final content = _content();
    if (!glass) return _solid(context, content);

    return ListenableBuilder(
      listenable: rise,
      // Built once: the rise only reshapes the frame around it.
      child: content,
      builder: (context, content) {
        final risen = rise.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: const Interval(0, 0.25).transform(risen),
              // The handle stays a button for screen readers while unseen.
              alwaysIncludeSemantics: true,
              child: _liquid(context, content!, risen),
            ),
            // Fully risen it is the panel's own top edge: the panel's grip
            // takes over, and scrolls with the list.
            if (risen < 1)
              ClosestGlassHandle(
                rise: risen,
                panelWidth: width,
                panelRadius: _radius,
              ),
          ],
        );
      },
    );
  }

  List<BoxShadow> get _shadows => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 16,
      offset: const Offset(0, -2),
    ),
  ];

  Widget _solid(BuildContext context, Widget content) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(_radius),
        ),
        border: docked ? Border.all(color: colors.border) : null,
        boxShadow: _shadows,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(_radius),
        ),
        child: content,
      ),
    );
  }

  Widget _liquid(BuildContext context, Widget content, double risen) {
    final colors = context.colors;
    final shape = LiquidRiseBorder(
      rise: risen,
      radius: _radius,
      footHeight: footHeight,
      side: docked ? BorderSide(color: colors.border) : BorderSide.none,
    );
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: colors.surface,
        shape: shape,
        shadows: _shadows,
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: content,
      ),
    );
  }

  /// Same widgets before and after the first pull: the scrollable under
  /// the finger is kept, only what it shows changes.
  Widget _content() {
    return ValueListenableBuilder<bool>(
      valueListenable: opened,
      builder: (context, opened, _) => Consumer(
        builder: (context, ref, _) {
          final page = opened
              ? ref.watch(closestListingsProvider).valueOrNull?.listings
              : null;
          return LoadMoreOnScroll(
            enabled: page != null && page.hasMore && !page.loadingMore,
            onLoadMore: () =>
                ref.read(closestListingsProvider.notifier).loadMore(),
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: ClosestListingsHeader(
                    opened: opened,
                    gutter: ClosestSheetLayout.gutter(width),
                    onHandleTap: onHandleTap,
                  ),
                ),
                if (opened)
                  ClosestListingsBody(
                    width: width,
                    height: height,
                    onOpen: onOpen,
                  ),
                // The last cards scroll up out from behind the nav.
                if (opened && footHeight > 0)
                  SliverToBoxAdapter(child: SizedBox(height: footHeight)),
              ],
            ),
          );
        },
      ),
    );
  }
}
