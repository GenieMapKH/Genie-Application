import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/closest_listings/presentation/closest_liquid_shape.dart';
import 'package:tilomnov/features/closest_listings/presentation/widgets/liquid_rise_border.dart';

void main() {
  const panel = Rect.fromLTWH(0, 0, 390, 200);

  Path outline(double rise, {double footHeight = 0}) =>
      LiquidRiseBorder(rise: rise, footHeight: footHeight).getOuterPath(panel);

  test('resting and fully risen, it is the whole panel', () {
    for (final rise in [0.0, 1.0]) {
      final path = outline(rise);
      expect(path.contains(const Offset(195, 2)), isTrue);
      expect(path.contains(const Offset(30, 2)), isTrue);
      expect(path.contains(const Offset(380, 190)), isTrue);
      // The rounded top corners.
      expect(path.contains(const Offset(1, 1)), isFalse);
    }
  });

  test('partway, a drop hangs from the handle, the sides still low', () {
    final path = outline(0.3);

    // From the handle's middle down; the handle covers what is above.
    expect(path.contains(const Offset(195, 25)), isTrue);
    expect(path.contains(const Offset(195, 10)), isFalse);
    expect(path.contains(const Offset(20, 25)), isFalse);
    expect(path.contains(const Offset(20, 198)), isTrue);
  });

  test('the drop widens as it rises', () {
    bool coversAt(double rise, double x) =>
        outline(rise).contains(Offset(x, 40));

    expect(coversAt(0.2, 80), isFalse);
    expect(coversAt(0.8, 80), isTrue);
  });

  group('standing on the nav capsule', () {
    const capsule = 62.0;

    test('its foot is rounded like the capsule', () {
      for (final rise in [0.0, 0.3, 1.0]) {
        final path = outline(rise, footHeight: capsule);
        expect(path.contains(const Offset(195, 199)), isTrue);
        expect(path.contains(const Offset(1, 199)), isFalse);
      }
    });

    test('pulled a little, the drop meets the capsule without a gap', () {
      final path = outline(0.05, footHeight: capsule);
      final top = panel.bottom - capsule;

      // The capsule's top edge and the drop's neck just above it.
      expect(path.contains(Offset(195, top + 1)), isTrue);
      expect(path.contains(Offset(195, top - 1)), isTrue);
      // The capsule's own rounded corners, not squared yet.
      expect(path.contains(Offset(2, top + 2)), isFalse);
    });
  });

  test('the handle stretches into the panel top edge', () {
    final resting = ClosestLiquidShape.handle(0, 390, 22);
    final risen = ClosestLiquidShape.handle(1, 390, 22);

    expect(resting.width, ClosestLiquidShape.restingHandle.width);
    expect(risen.outerRect, const Rect.fromLTWH(0, 0, 390, 40));
    expect(risen.tlRadiusX, 22);
    expect(risen.blRadiusX, 0);
    // Its middle stays at the grip.
    expect(resting.center.dy, risen.center.dy);
  });
}
