import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/core/theme/app_motion.dart';
import 'package:tilomnov/features/closest_listings/presentation/closest_sheet_layout.dart';
import 'package:tilomnov/features/closest_listings/presentation/closest_sheet_spring.dart';
import 'package:tilomnov/features/closest_listings/presentation/widgets/closest_listing_tile.dart';
import 'package:tilomnov/features/closest_listings/presentation/widgets/closest_sheet_panel.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/presentation/widgets/detail/property_detail_sheet.dart';

/// The list under the map: rests as a handle on the bottom nav, pulls up
/// over the map to every listing, nearest first. Full width on phones, a
/// panel at the left on wide screens ([ClosestSheetLayout]).
///
/// Fill the space between the top of the screen and the bottom nav with it.
class ClosestListingsSheet extends ConsumerStatefulWidget {
  /// False while something else holds the bottom of the map (a listing's
  /// card, search results, drawing): it slides away and lets go.
  final bool visible;

  /// Size of the floating glass navigation capsule, when the glass bar is
  /// on; the sheet's box then ends at the capsule's bottom edge. On every
  /// screen the sheet is then as wide as the capsule and centred on it, its
  /// foot behind it: the resting handle is a glass pill in the middle above
  /// the capsule, and the panel swells out of the capsule as it is pulled.
  final Size? glassNav;

  const ClosestListingsSheet({super.key, required this.visible, this.glassNav});

  @override
  ConsumerState<ClosestListingsSheet> createState() =>
      _ClosestListingsSheetState();
}

class _ClosestListingsSheetState extends ConsumerState<ClosestListingsSheet>
    with SingleTickerProviderStateMixin {
  final _controller = DraggableScrollableController();
  late final _spring = ClosestSheetSpring(vsync: this, sheet: _controller);

  // These are notifiers, not setState fields, on purpose: rebuilding this
  // State rebuilds the DraggableScrollableSheet, which drops the drag in
  // progress (the sheet fell back to the bottom under the finger). Only the
  // parts that need them listen.

  /// Pulled up at least once: the list is read from then on.
  final _opened = ValueNotifier(false);

  /// Pulled up now: Back lets it down instead of leaving.
  final _raised = ValueNotifier(false);

  /// How far the glass handle has been pulled into the panel, 0 to 1.
  final _rise = ValueNotifier(0.0);

  double _peekExtent = 0;
  double _middleExtent = 0.5;
  double _sheetHeight = 1;

  /// The extents the sheet rests at, lowest first.
  List<double> _stops = const [0, 1];

  /// Which way the sheet last moved, for where a release settles.
  double _lastExtent = 0;
  bool _movingUp = true;

  /// The finger holding the sheet, how fast it goes, and whether it has
  /// moved the sheet (rather than scrolled the list or tapped).
  int? _finger;
  VelocityTracker? _fingerSpeed;
  bool _dragged = false;

  /// Between a finger's release and the spring taking over from the
  /// sheet's own reaction to it.
  bool _releasing = false;

  /// Slower than this, in logical pixels a second, a release keeps the
  /// direction the sheet last moved in.
  static const _stillSpeed = 40.0;

  static const _motion = Duration(milliseconds: 320);
  static const _curve = Cubic(0.16, 1.0, 0.3, 1.0);

  @override
  void didUpdateWidget(ClosestListingsSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible && !widget.visible) _lower();
  }

  @override
  void dispose() {
    _spring.dispose();
    _controller.dispose();
    _opened.dispose();
    _raised.dispose();
    _rise.dispose();
    super.dispose();
  }

  bool _onExtentChanged(DraggableScrollableNotification notification) {
    final extent = notification.extent;
    if ((extent - _lastExtent).abs() > 0.0005) {
      _movingUp = extent > _lastExtent;
      _lastExtent = extent;
      if (_finger != null && !_spring.isMoving) _dragged = true;
    }
    final raised = extent > _peekExtent + 0.01;
    _raised.value = raised;
    if (raised) _opened.value = true;
    final pulled = (extent - _peekExtent) * _sheetHeight;
    _rise.value = (pulled / ClosestSheetLayout.liquidRiseDistance).clamp(
      0.0,
      1.0,
    );
    return false;
  }

  /// The sheet stopped without a finger to settle it (moved some other
  /// way): on to the stop in the direction it was going.
  bool _onScrollEnd(ScrollEndNotification notification) {
    // The spring's own moves end scrolls too: not a release.
    if (_spring.isMoving || _releasing || _finger != null) return false;
    _settle(0);
    return false;
  }

  void _onFingerDown(PointerDownEvent event) {
    if (_finger != null) return;
    _finger = event.pointer;
    _dragged = false;
    // Caught mid-move: it stays under the finger.
    _spring.stop();
    _fingerSpeed = VelocityTracker.withKind(event.kind)
      ..addPosition(event.timeStamp, event.position);
  }

  void _onFingerMove(PointerMoveEvent event) {
    if (event.pointer != _finger) return;
    _fingerSpeed?.addPosition(event.timeStamp, event.position);
  }

  void _onFingerLifted(PointerEvent event) {
    if (event.pointer != _finger) return;
    _finger = null;
    // Upwards positive, as the sheet's extent grows.
    final speed = event is PointerUpEvent
        ? -(_fingerSpeed?.getVelocity().pixelsPerSecond.dy ?? 0)
        : 0.0;
    _fingerSpeed = null;
    if (!_dragged) return;
    // The sheet reacts to the release first (it starts a fling of its
    // own); the spring then takes over, at the finger's speed.
    _releasing = true;
    scheduleMicrotask(() {
      _releasing = false;
      if (mounted) _settle(speed);
    });
  }

  /// On to the stop the sheet's [speed] (logical pixels a second, upwards
  /// positive) carries it to, or in the direction it last moved.
  void _settle(double speed) {
    if (!_controller.isAttached) return;
    final size = _controller.size;
    final velocity = speed / _sheetHeight;
    final projected = (size + velocity * ClosestSheetLayout.releaseProjection)
        .clamp(_stops.first, _stops.last);
    final target = ClosestSheetLayout.settleExtent(
      projected,
      _stops,
      movingUp: speed.abs() > _stillSpeed ? speed > 0 : _movingUp,
    );
    if ((target - size).abs() > 0.002) _moveTo(target, velocity: velocity);
  }

  void _toggle() {
    if (!_controller.isAttached) return;
    _moveTo(_raised.value ? _peekExtent : _middleExtent);
  }

  void _lower() {
    if (_controller.isAttached && _raised.value) _moveTo(_peekExtent);
  }

  void _moveTo(double extent, {double velocity = 0}) {
    _spring.moveTo(
      extent,
      velocity: velocity,
      animate: !AppMotion.reduceMotionOf(context),
    );
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
    final nav = widget.glassNav;
    // Grows out of the glass capsule: as wide, its foot behind it. Docking
    // at the side is for the full-width bar only (the capsule is centred).
    final docked = nav == null && ClosestSheetLayout.isDocked(screenWidth);
    final width = nav?.width ?? ClosestSheetLayout.width(screenWidth);
    final foot = nav?.height ?? 0.0;
    final height = constraints.maxHeight;
    _sheetHeight = height;
    _peekExtent = ClosestSheetLayout.peekExtent(height, foot: foot);
    final middle = ClosestSheetLayout.middleExtent(height);
    // Only a real stop between resting and fully up.
    final hasMiddle = middle > _peekExtent + 0.05 && middle < 0.95;
    _middleExtent = hasMiddle ? middle : 1.0;
    _stops = [_peekExtent, if (hasMiddle) middle, 1.0];

    return Align(
      alignment: nav != null ? Alignment.bottomCenter : Alignment.bottomLeft,
      child: Padding(
        padding: EdgeInsets.only(
          left: docked ? ClosestSheetLayout.dockMargin : 0,
        ),
        child: SizedBox(
          width: width,
          height: height,
          // Only watches the finger; the sheet still takes the drag.
          child: Listener(
            onPointerDown: _onFingerDown,
            onPointerMove: _onFingerMove,
            onPointerUp: _onFingerLifted,
            onPointerCancel: _onFingerLifted,
            child: _buildSheet(width, height, docked, foot),
          ),
        ),
      ),
    );
  }

  Widget _buildSheet(double width, double height, bool docked, double foot) {
    return NotificationListener<ScrollEndNotification>(
      onNotification: _onScrollEnd,
      child: NotificationListener<DraggableScrollableNotification>(
        onNotification: _onExtentChanged,
        child: DraggableScrollableSheet(
          controller: _controller,
          initialChildSize: _peekExtent,
          minChildSize: _peekExtent,
          // Settled on release by `_settle`, which follows the finger (the
          // built-in snap goes to the nearest stop).
          snap: false,
          builder: (context, scrollController) => ClosestSheetPanel(
            scrollController: scrollController,
            width: width,
            height: height,
            docked: docked,
            glass: widget.glassNav != null,
            footHeight: foot,
            opened: _opened,
            rise: _rise,
            onHandleTap: _toggle,
            onOpen: _openDetail,
          ),
        ),
      ),
    );
  }
}
