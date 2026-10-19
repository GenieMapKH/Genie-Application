import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:genie/features/home/presentation/providers/map_camera_provider.dart';
import 'package:genie/features/home/presentation/widgets/map/liquid/liquid_cluster_painter.dart';
import 'package:genie/features/home/utils/map/cluster_transition.dart';

/// Plays a [ClusterTransition] over the map, frame by frame.
///
/// When the drops have landed it calls [onLanded], so the map shows its own
/// markers again underneath, holds the last frame while the map draws them
/// (a few frames late), then fades out into them before [onDone]. The map's
/// markers are bitmaps and differ from the drops by a hair; a fade hides
/// that where a cut would flicker. If the map moves after landing the
/// overlay leaves at once: its last frame stands still, and would show every
/// dot and count twice beside the map's own, moving ones.
class LiquidClusterOverlay extends StatefulWidget {
  final ClusterTransition transition;
  final MapCamera Function() readCamera;
  final VoidCallback onLanded;
  final VoidCallback onDone;

  const LiquidClusterOverlay({
    super.key,
    required this.transition,
    required this.readCamera,
    required this.onLanded,
    required this.onDone,
  });

  /// How long the last frame stays fully over the map's own markers, then
  /// how long it takes to fade into them.
  static const hold = Duration(milliseconds: 120);
  static const fadeOut = Duration(milliseconds: 220);
  static Duration get handover => hold + fadeOut;

  @override
  State<LiquidClusterOverlay> createState() => _LiquidClusterOverlayState();
}

class _LiquidClusterOverlayState extends State<LiquidClusterOverlay>
    with SingleTickerProviderStateMixin {
  final _progress = ValueNotifier<double>(0);
  final _opacity = ValueNotifier<double>(1);
  late final Ticker _ticker = createTicker(_tick);
  bool _landed = false;

  /// The camera when the drops landed.
  MapCamera? _landedCamera;

  /// The ticker's time when the current transition arrived.
  Duration? _startedAt;
  Duration _lastTick = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  @override
  void didUpdateWidget(LiquidClusterOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transition == widget.transition) return;
    // A new zoom level mid-animation: the drops carry on from where they are.
    _landed = false;
    _progress.value = 0;
    _opacity.value = 1;
    _startedAt = _ticker.isActive ? _lastTick : null;
    if (!_ticker.isActive) _ticker.start();
  }

  void _tick(Duration elapsed) {
    _lastTick = elapsed;
    final played = elapsed - (_startedAt ??= elapsed);
    _progress.value =
        (played.inMicroseconds / widget.transition.duration.inMicroseconds)
            .clamp(0.0, 1.0);

    if (!_landed && _progress.value >= 1) {
      _landed = true;
      _landedCamera = widget.readCamera();
      widget.onLanded();
    }
    _opacity.value = _opacityAfter(played - widget.transition.duration);

    // Every camera move sets a new camera, so sameness means it stood still.
    final moved = _landed && !identical(widget.readCamera(), _landedCamera);
    if (moved ||
        played >= widget.transition.duration + LiquidClusterOverlay.handover) {
      _ticker.stop();
      widget.onDone();
    }
  }

  static double _opacityAfter(Duration sinceLanding) {
    final fading = sinceLanding - LiquidClusterOverlay.hold;
    if (fading <= Duration.zero) return 1;
    final t =
        fading.inMicroseconds / LiquidClusterOverlay.fadeOut.inMicroseconds;
    return 1 - Curves.easeInOut.transform(t.clamp(0.0, 1.0));
  }

  @override
  void dispose() {
    _ticker.dispose();
    _progress.dispose();
    _opacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ValueListenableBuilder<double>(
        valueListenable: _opacity,
        builder: (context, opacity, drops) =>
            Opacity(opacity: opacity, child: drops),
        child: RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: LiquidClusterPainter(
              transition: widget.transition,
              progress: _progress,
              readCamera: widget.readCamera,
            ),
          ),
        ),
      ),
    );
  }
}
