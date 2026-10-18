import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:genie/features/home/presentation/providers/map_camera_provider.dart';
import 'package:genie/features/home/presentation/widgets/map/liquid/liquid_cluster_painter.dart';
import 'package:genie/features/home/utils/map/cluster_transition.dart';

/// Plays a [ClusterTransition] over the map, frame by frame.
///
/// When the drops have landed it calls [onLanded], so the map shows its own
/// markers again underneath, and keeps the last frame up a little longer
/// before [onDone]: the map draws markers a frame or two late, and the dots
/// would blink if the overlay left first.
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

  /// How long the last frame stays over the map's own markers.
  static const handover = Duration(milliseconds: 150);

  @override
  State<LiquidClusterOverlay> createState() => _LiquidClusterOverlayState();
}

class _LiquidClusterOverlayState extends State<LiquidClusterOverlay>
    with SingleTickerProviderStateMixin {
  final _progress = ValueNotifier<double>(0);
  late final Ticker _ticker = createTicker(_tick);
  bool _landed = false;

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
    _startedAt = _ticker.isActive ? _lastTick : null;
    if (!_ticker.isActive) _ticker.start();
  }

  void _tick(Duration elapsed) {
    _lastTick = elapsed;
    final played = elapsed - (_startedAt ??= elapsed);
    _progress.value =
        (played.inMicroseconds / ClusterTransition.duration.inMicroseconds)
            .clamp(0.0, 1.0);

    if (!_landed && _progress.value >= 1) {
      _landed = true;
      widget.onLanded();
    }
    if (played >= ClusterTransition.duration + LiquidClusterOverlay.handover) {
      _ticker.stop();
      widget.onDone();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
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
    );
  }
}
