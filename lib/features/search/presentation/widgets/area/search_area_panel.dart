import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/search/presentation/search_layout.dart';
import 'package:genie/features/search/presentation/view_models/search_area_controller.dart';
import 'package:genie/features/search/presentation/widgets/area/search_area_header.dart';
import 'package:genie/features/search/presentation/widgets/area/search_area_listings.dart';

/// The listings of the place or person the map shows after a search. On
/// phones a sheet that can be dragged up over the map; on wide screens a
/// panel beside it. Draws nothing while no search is shown.
///
/// Fill the map's stack with it: [margin] keeps it clear of the controls
/// above it and the navigation bar below it.
class SearchAreaPanel extends ConsumerWidget {
  final EdgeInsets margin;
  final ValueChanged<PropertyModel> onOpenProperty;

  const SearchAreaPanel({
    super.key,
    required this.margin,
    required this.onOpenProperty,
  });

  /// Grab handle above the header of the phone sheet.
  static const double _handleHeight = 20;

  /// The part of a [screen]-sized map the panel covers while resting, so the
  /// camera can frame the area in what stays visible.
  static EdgeInsets coveredInsets(Size screen, EdgeInsets margin) {
    if (SearchLayout.isWide(screen.width)) {
      return EdgeInsets.only(
        left: margin.left + SearchLayout.sidePanelWidth(screen.width),
      );
    }
    final available = screen.height - margin.vertical;
    return EdgeInsets.only(
      bottom: margin.bottom + SearchLayout.sheetRestingHeight(available),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchAreaControllerProvider);
    if (state == null) return const SizedBox.shrink();

    final controller = ref.read(searchAreaControllerProvider.notifier);
    final header = SearchAreaHeader(state: state, onClose: controller.clear);
    final listings = SearchAreaListings(
      state: state,
      onOpenProperty: onOpenProperty,
      onRetry: controller.retry,
    );
    final width = MediaQuery.sizeOf(context).width;

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
        : _BottomSheet(
            key: key,
            margin: margin,
            header: header,
            listings: listings,
          );
  }
}

class _BottomSheet extends StatelessWidget {
  final EdgeInsets margin;
  final Widget header;
  final Widget listings;

  const _BottomSheet({
    super.key,
    required this.margin,
    required this.header,
    required this.listings,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Positioned(
      left: 0,
      right: 0,
      top: margin.top,
      bottom: margin.bottom,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.maxHeight;
          if (available <= 0) return const SizedBox.shrink();

          final resting = SearchLayout.sheetRestingHeight(
            available,
          ).clamp(0.0, available);
          final collapsed =
              (SearchAreaPanel._handleHeight + SearchAreaHeader.height).clamp(
                0.0,
                resting,
              );
          final initial = resting / available;

          return _SlideUp(
            child: DraggableScrollableSheet(
              initialChildSize: initial,
              minChildSize: collapsed / available,
              maxChildSize: 1,
              snap: true,
              snapSizes: [initial],
              builder: (context, scrollController) {
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: CustomScrollView(
                      controller: scrollController,
                      slivers: [
                        PinnedHeaderSliver(
                          child: ColoredBox(
                            color: colors.surface,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const _GrabHandle(),
                                header,
                                Divider(height: 1, color: colors.divider),
                              ],
                            ),
                          ),
                        ),
                        listings,
                        const SliverPadding(
                          padding: EdgeInsets.only(bottom: 16),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
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
      child: _SlideUp(
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

class _GrabHandle extends StatelessWidget {
  const _GrabHandle();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: SearchAreaPanel._handleHeight,
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: context.colors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

/// Rises and fades in once when it first appears.
class _SlideUp extends StatelessWidget {
  final Widget child;

  const _SlideUp({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: const Cubic(0.16, 1.0, 0.3, 1.0),
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: FractionalTranslation(
          translation: Offset(0, (1 - t) * 0.08),
          child: child,
        ),
      ),
    );
  }
}
