import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/home/presentation/widgets/map/liquid/drop_on_screen.dart';
import 'package:genie/features/home/presentation/widgets/map/liquid/liquid_necks.dart';

DropOnScreen _drop(double x, {double cohesion = 1}) => (
  center: Offset(x, 0),
  radius: 12.5,
  ring: 1,
  cohesion: cohesion,
  outline: RRect.fromRectAndRadius(
    Rect.fromCircle(center: Offset(x, 0), radius: 12.5),
    const Radius.circular(12.5),
  ),
  border: 1,
  color: const Color(0xFF028752),
  tail: 0,
  tagness: 0,
);

void main() {
  test('drops far apart have no neck', () {
    final necks = LiquidNecks.joining([_drop(0), _drop(60)]);
    expect(necks.core.getBounds().isEmpty, isTrue);
    expect(necks.rim.getBounds().isEmpty, isTrue);
  });

  test('touching drops share a neck thinner than either drop', () {
    // Green radii 11.5 each, just touching at x = 11.5.
    final necks = LiquidNecks.joining([_drop(0), _drop(23)]);
    expect(necks.core.contains(const Offset(11.5, 0)), isTrue);
    expect(necks.core.contains(const Offset(11.5, 5)), isTrue);
    expect(necks.core.contains(const Offset(11.5, 9)), isFalse);
    // The white ring hugs the green neck.
    expect(necks.rim.contains(const Offset(11.5, 6.5)), isTrue);
  });

  test('the neck thins out as the drops pull apart', () {
    double waist(double gap) {
      final necks = LiquidNecks.joining([_drop(0), _drop(23 + gap)]);
      final mid = (23 + gap) / 2;
      var h = 0.0;
      while (necks.core.contains(Offset(mid, h + 0.1))) {
        h += 0.1;
      }
      return h;
    }

    final widths = [
      for (final gap in [0.0, 3.0, 6.0, 9.0]) waist(gap),
    ];
    for (var i = 1; i < widths.length; i++) {
      expect(widths[i], lessThan(widths[i - 1]));
    }
    expect(widths.last, lessThan(1));
  });

  test('a drop turning into a tag lets go', () {
    double waist(double cohesion) {
      final necks = LiquidNecks.joining([
        _drop(0),
        _drop(23, cohesion: cohesion),
      ]);
      var h = 0.0;
      while (necks.core.contains(Offset(11.5, h + 0.1))) {
        h += 0.1;
      }
      return h;
    }

    expect(waist(0.5), lessThan(waist(1)));
    expect(waist(0), 0);
  });

  test('drops at the same spot are not joined', () {
    final necks = LiquidNecks.joining([_drop(0), _drop(0)]);
    expect(necks.core.getBounds().isEmpty, isTrue);
  });
}
