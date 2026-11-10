import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Keeps the search region clear while softening the surrounding map.
class SearchAreaHighlight extends StatelessWidget {
  final ValueListenable<List<Offset>> points;
  const SearchAreaHighlight({super.key, required this.points});

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ValueListenableBuilder<List<Offset>>(
      valueListenable: points,
      builder: (context, points, _) {
        if (points.length < 3) return const SizedBox.shrink();
        return ClipPath(
          clipper: SearchAreaOutsideClipper(points),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.30)),
          ),
        );
      },
    ),
  );
}

class SearchAreaOutsideClipper extends CustomClipper<Path> {
  final List<Offset> points;
  const SearchAreaOutsideClipper(this.points);

  @override
  Path getClip(Size size) => Path()
    ..fillType = PathFillType.evenOdd
    ..addRect(Offset.zero & size)
    ..addPolygon(points, true);

  @override
  bool shouldReclip(SearchAreaOutsideClipper oldClipper) =>
      !listEquals(points, oldClipper.points);
}
