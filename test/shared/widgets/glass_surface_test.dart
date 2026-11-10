import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/shared/widgets/glass/glass_surface.dart';

/// [matrix] applied to an opaque colour of channels 0..1.
List<double> _apply(List<double> matrix, List<double> rgb) => [
  for (var row = 0; row < 3; row++)
    matrix[row * 5] * rgb[0] +
        matrix[row * 5 + 1] * rgb[1] +
        matrix[row * 5 + 2] * rgb[2],
];

void main() {
  group('glass colour boost', () {
    test('at 1 it changes nothing', () {
      final out = _apply(GlassSurface.saturationMatrix(1), [0.2, 0.5, 0.9]);
      expect(out[0], closeTo(0.2, 1e-9));
      expect(out[1], closeTo(0.5, 1e-9));
      expect(out[2], closeTo(0.9, 1e-9));
    });

    test('greys stay grey, colours grow more vivid', () {
      final matrix = GlassSurface.saturationMatrix(1.8);
      for (final grey in [0.0, 0.4, 1.0]) {
        for (final channel in _apply(matrix, [grey, grey, grey])) {
          expect(channel, closeTo(grey, 1e-9));
        }
      }
      // A muted green: further from grey afterwards.
      final out = _apply(matrix, [0.4, 0.6, 0.4]);
      expect(out[1] - out[0], greaterThan(0.2));
    });
  });
}
