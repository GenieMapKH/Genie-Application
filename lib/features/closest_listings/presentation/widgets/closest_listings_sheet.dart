import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/closest_listings/presentation/closest_sheet_layout.dart';
import 'package:tilomnov/features/closest_listings/presentation/view_models/closest_listings_provider.dart';
import 'package:tilomnov/features/closest_listings/presentation/widgets/closest_glass_handle.dart';
import 'package:tilomnov/features/closest_listings/presentation/widgets/closest_listing_tile.dart';
import 'package:tilomnov/features/closest_listings/presentation/widgets/closest_listings_body.dart';
import 'package:tilomnov/features/closest_listings/presentation/widgets/closest_listings_header.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/presentation/widgets/detail/property_detail_sheet.dart';
import 'package:tilomnov/shared/widgets/lists/load_more_on_scroll.dart';

/// The list under the map: rests as a handle on the bottom nav, pulls up
/// over the map to every listing, nearest first. Full width on phones, a
/// panel at the left on wide screens ([ClosestSheetLayout]).
///
/// Fill the space between the top of the screen and the bottom nav with it.
class ClosestListingsSheet extends ConsumerStatefulWidget {
  /// False while something else holds the bottom of the map (a listing's
  /// card, search results, drawing): it slides away and lets go.
  final bool visible;

  /// The glass navigation bar is on: the resting handle is a glass pill
  /// sitting on it, and the opaque panel only shows once pulled up.
  final bool glass;

  /// Height of the strip between the sheet's bottom edge and the screen's.
  /// The pulled-up sheet fills it with its own colour, so the map does not
  /// show around a floating nav bar.
  final double underNavHeight;

  const ClosestListingsSheet({
    super.key,
    required this.visible,
    this.glass = false,
    this.underNavHeight = 0,
  });

  @override
  ConsumerState<ClosestListingsSheet> createState() =>
      _ClosestListingsSheetState();
}

class _ClosestListingsSheetState extends ConsumerState<ClosestListingsSheet> {
  final _controller = DraggableScrollableController();

  // These are notifiers, not setState fields, on purpose: rebuilding this
  // State rebuilds the DraggableScrollableSheet, which drops the drag in
  // progress (the sheet fell back to the bottom under the finger). Only the
  // parts that need them listen.

  /// Pulled up at least once: the list is read from then on.
  final _opened = ValueNotifier(false);

  /// Pulled up now: Back lets it down instead of leaving.
  final _raised = ValueNotifier(false);

  double _peekExtent = 0;
  double _middleExtent = 0.5;

  /// The extents the sheet rests at, lowest first.
  List<double> _stops = const [0, 1];

  /// Whether the sheet is being moved by `_animateTo`, not a finger.
  bool _animating = false;

  /// Which way the sheet last moved, for where a release settles.
  double _lastExtent = 0;
  bool _movingUp = true;

  static const _motion = Duration(milliseconds: 320);
  static const _curve = Cubic(0.16, 1.0, 0.3, 1.0);

  @override
  void didUpdateWidget(ClosestListingsSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible && !widget.visible) _lower();
  }

  @override
  void dispose() {
    _controller.dispose();
    _opened.dispose();
    _raised.dispose();
    super.dispose();
  }

  bool _onExtentChanged(DraggableScrollableNotification notification) {
    final extent = notification.extent;
    if ((extent - _lastExtent).abs() > 0.0005) {
      _movingUp = extent > _lastExtent;
      _lastExtent = extent;
    }
    final raised = extent > _peekExtent + 0.01;
    _raised.value = raised;
    if (raised) _opened.value = true;
    return false;
  }

  /// The finger came off and the sheet stopped: on to the stop in the
  /// direction it was going, or back, if it was hardly moved.
  bool _onScrollEnd(ScrollEndNotification notification) {
    // Animating the sheet ends a scroll of its own: not a new release.
    if (_animating || !_controller.isAttached) return false;
    final target = ClosestSheetLayout.settleExtent(
      _controller.size,
      _stops,
      movingUp: _movingUp,
    );
    if ((target - _controller.size).abs() > 0.002) _animateTo(target);
    return false;
  }

  void _toggle() {
    if (!_controller.isAttached) return;
    _animateTo(_raised.value ? _peekExtent : _middleExtent);
  }

  void _lower() {
    if (_controller.isAttached && _raised.value) _animateTo(_peekExtent);
  }

  Future<void> _animateTo(double extent) async {
    _animating = true;
    try {
      await _controller.animateTo(extent, duration: _motion, curve: _curve);
    } finally {
      _animating = false;
    }
  }

  void _openDetail(PropertyModel property) {
    Navigator.of(context).push(_detailRoute(property));
  }

  /// A recommendation was tapped: its sheet takes the place of this one.
  Route<void> _detailRoute(PropertyModel property, {Rect? origin}) {
    return PropertyDetailSheet.route(
      property,
      heroTag: ClosestListingTile.heroTagOf(property.id),
      origin: origin,
      onOpenProperty: (next, tileRect) => Navigator.of(
        context,
      ).pushReplacement(_detailRoute(next, origin: tileRect)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _raised,
      builder: (context, raised, child) => PopScope(
        canPop: !raised,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _lower();
        },
        child: child!,
      ),
      child: IgnorePointer(
        ignoring: !widget.visible,
        child: AnimatedSlide(
          offset: widget.visible ? Offset.zero : const Offset(0, 1),
          duration: _motion,
          curve: _curve,
          child: LayoutBuilder(builder: _buildSized),
        ),
      ),
    );
  }

  Widget _buildSized(BuildContext context, BoxConstraints constraints) {
    final screenWidth = constraints.maxWidth;
    final docked = ClosestSheetLayout.isDocked(screenWidth);
    final width = ClosestSheetLayout.width(screenWidth);
    final height = constraints.maxHeight;
    _peekExtent = ClosestSheetLayout.peekExtent(height);
    final middle = ClosestSheetLayout.middleExtent(height);
    // Only a real stop between resting and fully up.
    final hasMiddle = middle > _peekExtent + 0.05 && middle < 0.95;
    _middleExtent = hasMiddle ? middle : 1.0;
    _stops = [_peekExtent, if (hasMiddle) middle, 1.0];

    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: EdgeInsets.only(
          left: docked ? ClosestSheetLayout.dockMargin : 0,
        ),
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              NotificationListener<ScrollEndNotification>(
                onNotification: _onScrollEnd,
                child: NotificationListener<DraggableScrollableNotification>(
                  onNotification: _onExtentChanged,
                  child: DraggableScrollableSheet(
                    controller: _controller,
                    initialChildSize: _peekExtent,
                    minChildSize: _peekExtent,
                    // Settled by `_onScrollEnd`, which follows the finger's
                    // direction (the built-in snap goes to the nearest stop).
                    snap: false,
                    builder: (context, scrollController) => _buildPanel(
                      context,
                      scrollController,
                      width,
                      height,
                      docked,
                    ),
                  ),
                ),
              ),
              if (widget.underNavHeight > 0) _buildUnderNav(context, height),
            ],
          ),
        ),
      ),
    );
  }

  /// The sheet's colour below its bottom edge, behind the floating nav bar.
  /// Only there while pulled up; resting, the glass handle sits on the map.
  Widget _buildUnderNav(BuildContext context, double sheetHeight) {
    return Positioned(
      left: 0,
      right: 0,
      // A pixel of overlap so no seam shows between it and the panel.
      top: sheetHeight - 1,
      height: widget.underNavHeight + 1,
      child: IgnorePointer(
        child: ValueListenableBuilder<bool>(
          valueListenable: _raised,
          builder: (context, raised, _) => AnimatedOpacity(
            opacity: raised ? 1 : 0,
            duration: const Duration(milliseconds: 150),
            child: ColoredBox(color: context.colors.surface),
          ),
        ),
      ),
    );
  }

  Widget _buildPanel(
    BuildContext context,
    ScrollController scrollController,
    double width,
    double height,
    bool docked,
  ) {
    final panel = _buildOpaquePanel(
      context,
      scrollController,
      width,
      height,
      docked,
    );
    if (!widget.glass) return panel;

    // Resting, only the glass handle shows; the panel fades in as it rises.
    return ValueListenableBuilder<bool>(
      valueListenable: _raised,
      builder: (context, raised, _) => Stack(
        fit: StackFit.expand,
        children: [
          AnimatedOpacity(
            opacity: raised ? 1 : 0,
            duration: const Duration(milliseconds: 150),
            // The handle stays a button for screen readers while unseen.
            alwaysIncludeSemantics: true,
            child: panel,
          ),
          ClosestGlassHandle(raised: raised),
        ],
      ),
    );
  }

  Widget _buildOpaquePanel(
    BuildContext context,
    ScrollController scrollController,
    double width,
    double height,
    bool docked,
  ) {
    final colors = context.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: docked ? Border.all(color: colors.border) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        // Same widgets before and after the first pull: the scrollable under
        // the finger is kept, only what it shows changes.
        child: ValueListenableBuilder<bool>(
          valueListenable: _opened,
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
                        onHandleTap: _toggle,
                      ),
                    ),
                    if (opened)
                      ClosestListingsBody(
                        width: width,
                        height: height,
                        onOpen: _openDetail,
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
