import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:genie/features/home/presentation/providers/map_camera_provider.dart';
import 'package:genie/features/home/presentation/widgets/map/liquid/drop_on_screen.dart';
import 'package:genie/features/home/presentation/widgets/map/liquid/liquid_labels.dart';
import 'package:genie/features/home/presentation/widgets/map/liquid/liquid_necks.dart';
import 'package:genie/features/home/utils/map/cluster_layout.dart';
import 'package:genie/features/home/utils/map/cluster_transition.dart';
import 'package:genie/features/home/utils/map/map_camera_focus.dart';
import 'package:genie/features/home/utils/map/markers/property_markers.dart';

/// Paints a [ClusterTransition] at [progress] over a flat, north-up map
/// whose camera is [readCamera], filling the map's whole frame.
///
/// Each drop is a plain circle like the map's own dots, and drops near each
/// other are joined by a neck ([LiquidNecks]), so they fuse like liquid and
/// stretch apart, with edges as crisp as the dots they stand in for. Drops
/// becoming price tags let go of each other and stretch into their tag.
class LiquidClusterPainter extends CustomPainter {
  final ClusterTransition transition;
  final ValueNotifier<double> progress;
  final MapCamera Function() readCamera;

  LiquidClusterPainter({
    required this.transition,
    required this.progress,
    required this.readCamera,
  }) : super(repaint: progress);

  /// Drops this far off screen are not painted.
  static const _offscreenMargin = 80.0;

  /// Like the map markers' own soft shadow, so nothing changes when they
  /// take over.
  static const _shadowOffset = Offset(0, 3);
  static const _shadowColor = Color(0x2B000000);
  static const _shadowBlur = 4.0;

  /// Drops at least this much a tag are drawn one by one, each with its own
  /// border, as the map draws its tags; rounder ones fuse.
  static const _tagFrom = 0.5;

  @override
  void paint(Canvas canvas, Size size) {
    final camera = readCamera();
    final p = progress.value;
    final drops = _dropsOnScreen(p, camera, size);
    final necks = LiquidNecks.joining(drops);
    final liquid = [
      for (final d in drops)
        if (d.tagness < _tagFrom) d,
    ];

    _paintShadow(canvas, Offset.zero & size, drops, necks.rim);
    // The white ring is the fused outline; the colour fills it, so drops
    // that touch share one ring.
    _paintOutlines(canvas, liquid, Colors.white);
    canvas.drawPath(necks.rim, Paint()..color = Colors.white);
    _paintInsides(canvas, liquid);
    canvas.drawPath(necks.core, Paint()..color = PropertyMarkers.green);
    for (final d in drops) {
      if (d.tagness < _tagFrom) continue;
      _paintOutlines(canvas, [d], Colors.white);
      _paintInsides(canvas, [d]);
    }

    Offset centerOf(ClusterSpot spot) =>
        _toScreen(spot.position, camera, size) - Offset(0, spot.lift);
    LiquidLabels.paintOutgoing(canvas, transition.outgoingLabels, p, centerOf);
    LiquidLabels.paintIncoming(canvas, transition.incomingLabels, p, centerOf);
  }

  /// The drops at linear progress [p] near the screen. Listings travelling
  /// together are one drop: drawn once, joined once.
  List<DropOnScreen> _dropsOnScreen(double p, MapCamera camera, Size size) {
    final visible = (Offset.zero & size).inflate(_offscreenMargin);
    final drops = <DropOnScreen>{};
    for (final drop in transition.drops.values) {
      final point = _toScreen(drop.positionAt(p), camera, size);
      if (!visible.contains(point)) continue;
      drops.add(dropOnScreen(drop, p, point));
    }
    return drops.toList();
  }

  static void _paintShadow(
    Canvas canvas,
    Rect bounds,
    List<DropOnScreen> drops,
    Path necks,
  ) {
    canvas
      ..saveLayer(
        bounds,
        Paint()
          ..color = _shadowColor
          ..imageFilter = ui.ImageFilter.blur(
            sigmaX: _shadowBlur,
            sigmaY: _shadowBlur,
          ),
      )
      ..translate(_shadowOffset.dx, _shadowOffset.dy);
    for (final d in drops) {
      if (d.shadow <= 0) continue;
      canvas.drawRRect(
        d.outline,
        Paint()..color = Colors.black.withValues(alpha: d.shadow),
      );
    }
    canvas
      ..drawPath(necks, Paint()..color = Colors.black)
      ..restore();
  }

  static void _paintOutlines(
    Canvas canvas,
    List<DropOnScreen> drops,
    Color color,
  ) {
    final paint = Paint()..color = color;
    for (final d in drops) {
      canvas.drawRRect(d.outline, paint);
    }
  }

  static void _paintInsides(Canvas canvas, List<DropOnScreen> drops) {
    for (final d in drops) {
      canvas.drawRRect(d.outline.deflate(d.border), Paint()..color = d.color);
    }
  }

  /// Where [point] is drawn in a map frame of [size] centred on the camera.
  static Offset _toScreen(LatLng point, MapCamera camera, Size size) {
    final p = MapCameraFocus.worldPixel(point, camera.zoom);
    final c = MapCameraFocus.worldPixel(camera.center, camera.zoom);
    return size.center(Offset(p.x - c.x, p.y - c.y));
  }

  @override
  bool shouldRepaint(LiquidClusterPainter old) =>
      old.transition != transition || old.progress != progress;
}
