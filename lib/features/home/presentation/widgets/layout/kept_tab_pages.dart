import 'package:flutter/material.dart';

import 'package:tilomnov/core/theme/app_motion.dart';

/// Full-screen tab pages that cross-fade in and out, drifting slightly in the
/// direction of the tab order, and are kept once built.
///
/// A page is built the first time its tab is shown and then kept, hidden,
/// while another tab is shown. Coming back shows it exactly as it was (scroll
/// position, pictures already decoded) instead of building it again. A
/// hidden page does not paint, animate or take part in hero flights.
class KeptTabPages extends StatefulWidget {
  /// The tab shown now, and the one shown before it.
  final int current;
  final int previous;

  /// Whether tab [index] has a page here (other tabs show what is below).
  final bool Function(int index) hasPage;

  final Widget Function(BuildContext context, int index) pageBuilder;

  const KeptTabPages({
    super.key,
    required this.current,
    required this.previous,
    required this.hasPage,
    required this.pageBuilder,
  });

  @override
  State<KeptTabPages> createState() => _KeptTabPagesState();
}

class _KeptTabPagesState extends State<KeptTabPages> {
  /// Tabs shown so far, so built and kept.
  final Set<int> _opened = {};

  /// Where page [index] sits while tab [current] is shown: on screen, or off
  /// to the side of its place in the tab order.
  static Offset _placeOf(int index, int current) {
    if (index == current) return Offset.zero;
    return Offset(index < current ? -1.0 : 1.0, 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.current;
    final previous = widget.previous;
    if (widget.hasPage(current)) _opened.add(current);

    return Stack(
      children: [
        for (final index in _opened.toList()..sort())
          _KeptPage(
            key: ValueKey(index),
            place: _placeOf(index, current),
            enterFrom: _placeOf(index, previous),
            animate: index == current || index == previous,
            child: widget.pageBuilder(context, index),
          ),
      ],
    );
  }
}

/// One kept page: fades in at [place], or out towards it, and once it rests
/// off screen is hidden. Like the tabs of an iOS tab bar it does not sweep
/// across the screen: it only drifts a little, enough to say which way the
/// tabs lie. With reduced motion it switches at once.
class _KeptPage extends StatefulWidget {
  /// Where the page should be: [Offset.zero] on screen, ±1 off to a side.
  final Offset place;

  /// Where a page built just now starts its slide from.
  final Offset enterFrom;

  /// False for pages not involved in this tab change: they jump to [place]
  /// instead of sweeping across the screen.
  final bool animate;

  final Widget child;

  const _KeptPage({
    super.key,
    required this.place,
    required this.enterFrom,
    required this.animate,
    required this.child,
  });

  @override
  State<_KeptPage> createState() => _KeptPageState();
}

class _KeptPageState extends State<_KeptPage> {
  static const _fade = Duration(milliseconds: 240);

  /// How far a page drifts while fading, as a share of its width.
  static const _drift = 0.04;

  late Offset _offset;
  bool _sliding = false;

  @override
  void initState() {
    super.initState();
    _offset = widget.place;
    if (widget.animate && widget.enterFrom != widget.place) {
      // Built off screen, then faded in on the next frame.
      _offset = widget.enterFrom;
      _sliding = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _offset = widget.place);
      });
    }
  }

  @override
  void didUpdateWidget(_KeptPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.place != _offset) {
      _offset = widget.place;
      // A switch made at once has nothing to wait for.
      _sliding = widget.animate && !AppMotion.reduceMotionOf(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _offset == Offset.zero || _sliding;

    final duration = widget.animate && !AppMotion.reduceMotionOf(context)
        ? _fade
        : Duration.zero;

    return AnimatedSlide(
      offset: _offset * _drift,
      duration: duration,
      curve: AppMotion.easeOut,
      child: AnimatedOpacity(
        opacity: _offset == Offset.zero ? 1 : 0,
        duration: duration,
        curve: Curves.easeOut,
        onEnd: () {
          if (_sliding) setState(() => _sliding = false);
        },
        child: Offstage(
          offstage: !visible,
          child: TickerMode(
            enabled: visible,
            child: HeroMode(enabled: visible, child: widget.child),
          ),
        ),
      ),
    );
  }
}
