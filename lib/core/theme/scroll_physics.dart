import 'package:flutter/material.dart';

class GlidingScrollPhysics extends BouncingScrollPhysics {
  const GlidingScrollPhysics({super.parent});

  @override
  GlidingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return GlidingScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double frictionFactor(double overscrollFraction) =>
      super.frictionFactor(overscrollFraction) * 0.6; // Reduced friction for a smoother, longer glide
}
