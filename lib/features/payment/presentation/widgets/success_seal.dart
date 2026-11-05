import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The green wavy seal with a white tick that says a payment went through.
///
/// [progress] runs it from nothing (0) to done (1): the seal springs in with
/// a small turn, a ripple spreads from it, then the tick draws itself.
class SuccessSeal extends StatelessWidget {
  final Animation<double> progress;
  final double size;

  const SuccessSeal({super.key, required this.progress, this.size = 128});

  static const _top = Color(0xFF7EE36A);
  static const _bottom = Color(0xFF1FC79B);

  @override
  Widget build(BuildContext context) {
    final pop = CurvedAnimation(
      parent: progress,
      curve: const Interval(0, 0.55, curve: Curves.easeOutBack),
    );
    final ripple = CurvedAnimation(
      parent: progress,
      curve: const Interval(0.3, 1, curve: Curves.easeOutCubic),
    );
    final tick = CurvedAnimation(
      parent: progress,
      curve: const Interval(0.45, 0.8, curve: Curves.easeOutCubic),
    );

    return SizedBox.square(
      dimension: size * 1.5,
      child: AnimatedBuilder(
        animation: progress,
        builder: (context, _) => CustomPaint(
          painter: _SealPainter(
            pop: pop.value,
            ripple: ripple.value,
            tick: tick.value,
            radius: size / 2,
          ),
        ),
      ),
    );
  }
}

class _SealPainter extends CustomPainter {
  final double pop;
  final double ripple;
  final double tick;
  final double radius;

  _SealPainter({
    required this.pop,
    required this.ripple,
    required this.tick,
    required this.radius,
  });

  /// Bumps round the edge, and how deep they are.
  static const _waves = 12;
  static const _waveDepth = 0.075;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    _paintRipple(canvas, center);
    if (pop <= 0) return;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate((1 - pop) * -0.6);
    canvas.scale(pop);

    final seal = _sealPath();
    final bounds = Rect.fromCircle(center: Offset.zero, radius: radius);
    canvas.drawShadow(seal, const Color(0xFF1FC79B), 6, false);
    canvas.drawPath(
      seal,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [SuccessSeal._top, SuccessSeal._bottom],
        ).createShader(bounds),
    );
    _paintTick(canvas);
    canvas.restore();
  }

  /// A circle whose edge rises and falls [_waves] times: soft scallops.
  Path _sealPath() {
    final path = Path();
    const steps = 240;
    for (var i = 0; i <= steps; i++) {
      final angle = i / steps * 2 * math.pi;
      final r =
          radius * (1 - _waveDepth + _waveDepth * math.cos(_waves * angle));
      final point = Offset(math.cos(angle), math.sin(angle)) * r;
      i == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  void _paintRipple(Canvas canvas, Offset center) {
    if (ripple <= 0 || ripple >= 1) return;
    canvas.drawCircle(
      center,
      radius * (1 + 0.45 * ripple),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = SuccessSeal._bottom.withValues(alpha: 0.35 * (1 - ripple)),
    );
  }

  /// The tick, drawn from its short arm to the tip of the long one.
  void _paintTick(Canvas canvas) {
    if (tick <= 0) return;
    final unit = radius / 64;
    final full = Path()
      ..moveTo(-26 * unit, 2 * unit)
      ..lineTo(-8 * unit, 20 * unit)
      ..lineTo(27 * unit, -18 * unit);
    final metric = full.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * tick),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 15 * unit
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white.withValues(alpha: 0.96),
    );
  }

  @override
  bool shouldRepaint(_SealPainter oldDelegate) =>
      oldDelegate.pop != pop ||
      oldDelegate.ripple != ripple ||
      oldDelegate.tick != tick ||
      oldDelegate.radius != radius;
}
