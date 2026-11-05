import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:tilomnov/core/theme/app_motion.dart';
import 'package:tilomnov/features/subscription/domain/plan_tier.dart';
import 'package:tilomnov/features/subscription/presentation/plan_tier_style.dart';

/// Puts a paid tier's frame around a round profile picture: a ring of the
/// tier's metal with light slowly running round it, a soft glow, a medallion
/// on top, and for Diamond a few twinkling sparks. Free shows [child] bare.
class TierAvatarFrame extends StatefulWidget {
  final PlanTier tier;

  /// Diameter of the picture inside the frame.
  final double diameter;
  final Widget child;

  const TierAvatarFrame({
    super.key,
    required this.tier,
    required this.diameter,
    required this.child,
  });

  /// Width of the metal ring, and the gap between it and the picture.
  static const ringWidth = 4.0;
  static const gap = 3.0;

  @override
  State<TierAvatarFrame> createState() => _TierAvatarFrameState();
}

class _TierAvatarFrameState extends State<TierAvatarFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSpin();
  }

  @override
  void didUpdateWidget(TierAvatarFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSpin();
  }

  /// Light runs round only on a paid frame, and stands still with reduced
  /// motion.
  void _syncSpin() {
    final moves = widget.tier.isPaid && !AppMotion.reduceMotionOf(context);
    if (moves && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!moves) {
      _spin.stop();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.tier.isPaid) return widget.child;
    final style = PlanTierStyle.of(widget.tier);
    final outer =
        widget.diameter + 2 * (TierAvatarFrame.ringWidth + TierAvatarFrame.gap);

    return SizedBox.square(
      dimension: outer,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // The glow sits behind everything, round the ring.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: style.glow.withValues(alpha: 0.55),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          RepaintBoundary(
            child: CustomPaint(
              size: Size.square(outer),
              painter: _MetalRingPainter(
                style: style,
                spin: _spin,
                sparkles: widget.tier == PlanTier.diamond,
              ),
            ),
          ),
          widget.child,
          Positioned(
            top: -TierAvatarFrame.ringWidth - 10,
            child: _Medallion(style: style),
          ),
        ],
      ),
    );
  }
}

/// The tier's emblem in a small round of its metal, crowning the frame.
class _Medallion extends StatelessWidget {
  final PlanTierStyle style;

  const _Medallion({required this.style});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: style.metalGradient,
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: style.glow.withValues(alpha: 0.6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(style.icon, size: 18, color: style.onMetal),
    );
  }
}

/// The ring: the metal swept round the circle, turning with [spin] so a
/// highlight travels round it, and a thin bright edge inside.
class _MetalRingPainter extends CustomPainter {
  final PlanTierStyle style;
  final Animation<double> spin;
  final bool sparkles;

  _MetalRingPainter({
    required this.style,
    required this.spin,
    required this.sparkles,
  }) : super(repaint: spin);

  static const _sparkSpots = [0.08, 0.36, 0.61, 0.86];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - TierAvatarFrame.ringWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final turn = spin.value * 2 * math.pi;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = TierAvatarFrame.ringWidth
        ..shader = SweepGradient(
          colors: style.metal,
          transform: GradientRotation(turn),
        ).createShader(rect),
    );
    canvas.drawCircle(
      center,
      radius - TierAvatarFrame.ringWidth / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Colors.white.withValues(alpha: 0.6),
    );
    if (sparkles) _paintSparkles(canvas, center, radius);
  }

  /// Four-pointed sparks on the ring, each brightening in turn.
  void _paintSparkles(Canvas canvas, Offset center, double radius) {
    for (final (index, spot) in _sparkSpots.indexed) {
      final phase = (spin.value * 2 + index / _sparkSpots.length) % 1.0;
      final strength = math.sin(phase * math.pi);
      if (strength < 0.15) continue;
      final angle = spot * 2 * math.pi - math.pi / 2;
      final at = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      _paintSpark(canvas, at, 3 + 4 * strength, strength);
    }
  }

  void _paintSpark(Canvas canvas, Offset at, double reach, double strength) {
    final waist = reach * 0.22;
    final spark = Path()
      ..moveTo(at.dx, at.dy - reach)
      ..lineTo(at.dx + waist, at.dy - waist)
      ..lineTo(at.dx + reach, at.dy)
      ..lineTo(at.dx + waist, at.dy + waist)
      ..lineTo(at.dx, at.dy + reach)
      ..lineTo(at.dx - waist, at.dy + waist)
      ..lineTo(at.dx - reach, at.dy)
      ..lineTo(at.dx - waist, at.dy - waist)
      ..close();
    canvas.drawPath(
      spark,
      Paint()..color = Colors.white.withValues(alpha: strength),
    );
  }

  @override
  bool shouldRepaint(_MetalRingPainter oldDelegate) =>
      oldDelegate.style != style || oldDelegate.sparkles != sparkles;
}
