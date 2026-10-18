import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:genie/features/home/presentation/providers/map_camera_provider.dart';
import 'package:genie/features/home/utils/map/cluster_layout.dart';
import 'package:genie/features/home/utils/map/cluster_transition.dart';
import 'package:genie/features/home/utils/map/map_camera_focus.dart';
import 'package:genie/features/home/utils/map/markers/property_markers.dart';

/// Paints a [ClusterTransition] at [progress] over a flat, north-up map
/// whose camera is [readCamera], filling the map's whole frame.
///
/// The drops are blurred, then cut back to a hard edge where the blur is
/// half opaque ("gooey" effect): two drops near each other blur into one
/// another, so they fuse like liquid and stretch apart with a neck.
class LiquidClusterPainter extends CustomPainter {
  final ClusterTransition transition;
  final ValueNotifier<double> progress;
  final MapCamera Function() readCamera;

  LiquidClusterPainter({
    required this.transition,
    required this.progress,
    required this.readCamera,
  }) : super(repaint: progress);

  /// How far the drops melt into each other.
  static const _blur = 5.0;

  /// The cut-off shrinks a blurred circle a little; this puts it back.
  static const _blurShrink = 1.0;

  /// The white ring is the fused green grown evenly by about 2 px (a slight
  /// blur cut low down), so it always hugs the green: no white web between
  /// drops about to touch, no white speck where they part.
  static const _ringBlur = 1.5;
  static const _ringCut = 0.09;

  /// Drops this far off screen are not painted.
  static const _offscreenMargin = 80.0;

  @override
  void paint(Canvas canvas, Size size) {
    final camera = readCamera();
    final linear = progress.value;
    final t = ClusterTransition.curve.transform(linear);
    final visible = (Offset.zero & size).inflate(_offscreenMargin);

    final frames = <({Offset center, double radius, double ring})>[];
    for (final drop in transition.drops.values) {
      final center =
          _toScreen(drop.positionAt(t), camera, size) -
          Offset(0, drop.liftAt(t));
      if (!visible.contains(center)) continue;
      frames.add((
        center: center,
        radius: drop.radiusAt(t),
        ring: drop.ringAt(t),
      ));
    }

    final bounds = Offset.zero & size;
    _paintShadow(canvas, bounds, [
      for (final f in frames) (f.center + _shadowOffset, f.radius),
    ]);
    final fill = [for (final f in frames) (f.center, f.radius - f.ring)];
    _paintLayer(
      canvas,
      bounds,
      Paint()
        ..imageFilter = ui.ImageFilter.compose(
          outer: _cutOff(Colors.white, cut: _ringCut),
          inner: ui.ImageFilter.compose(
            outer: ui.ImageFilter.blur(sigmaX: _ringBlur, sigmaY: _ringBlur),
            inner: _gooFilter(const Color(0xFF000000)),
          ),
        ),
      fill,
    );
    _paintLayer(
      canvas,
      bounds,
      Paint()..imageFilter = _gooFilter(PropertyMarkers.green),
      fill,
    );

    // Old counts fade out as the drops leave; new ones fade in as they land.
    _paintLabels(
      canvas,
      transition.outgoingLabels,
      opacity: 1 - Interval(0, 0.35).transform(linear),
      camera: camera,
      size: size,
    );
    _paintLabels(
      canvas,
      transition.incomingLabels,
      opacity: const Interval(0.6, 1).transform(linear),
      camera: camera,
      size: size,
    );
  }

  /// Like the map markers' own soft shadow, so nothing changes when they
  /// take over.
  static const _shadowOffset = Offset(0, 3);

  static void _paintShadow(
    Canvas canvas,
    Rect bounds,
    List<(Offset, double)> circles,
  ) {
    _paintLayer(
      canvas,
      bounds,
      Paint()
        ..color = const Color(0x2B000000)
        ..imageFilter = ui.ImageFilter.compose(
          outer: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          inner: _gooFilter(const Color(0xFF000000)),
        ),
      circles,
    );
  }

  static void _paintLayer(
    Canvas canvas,
    Rect bounds,
    Paint layer,
    List<(Offset, double)> circles,
  ) {
    canvas.saveLayer(bounds, layer);
    final paint = Paint()..color = const Color(0xFF000000);
    for (final (center, radius) in circles) {
      canvas.drawCircle(center, radius + _blurShrink, paint);
    }
    canvas.restore();
  }

  /// Makes every pixel more than [cut] covered solid [color] and the rest
  /// clear.
  static ColorFilter _cutOff(Color color, {double cut = 0.5}) {
    const sharpness = 24.0;
    return ColorFilter.matrix([
      0, 0, 0, 0, color.r * 255, //
      0, 0, 0, 0, color.g * 255, //
      0, 0, 0, 0, color.b * 255, //
      0, 0, 0, sharpness, -sharpness * cut * 255,
    ]);
  }

  /// Blur, then cut back to a hard edge where the blur is half opaque.
  static ui.ImageFilter _gooFilter(Color color) {
    return ui.ImageFilter.compose(
      outer: _cutOff(color),
      inner: ui.ImageFilter.blur(
        sigmaX: _blur,
        sigmaY: _blur,
        tileMode: TileMode.decal,
      ),
    );
  }

  static void _paintLabels(
    Canvas canvas,
    List<ClusterSpot> spots, {
    required double opacity,
    required MapCamera camera,
    required Size size,
  }) {
    if (opacity <= 0) return;
    for (final spot in spots) {
      final label = TextPainter(
        text: TextSpan(
          text: spot.count > 999 ? '999+' : '${spot.count}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: opacity),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final center =
          _toScreen(spot.position, camera, size) - Offset(0, spot.lift);
      label.paint(canvas, center - Offset(label.width / 2, label.height / 2));
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
