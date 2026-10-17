import 'package:flutter_test/flutter_test.dart';
import 'package:genie/core/media/app_image_cache.dart';

void main() {
  group('AppImageCache.decodeWidth', () {
    test('uses the longer side, in device pixels, rounded up to a step', () {
      // 180 x 220 at 3x: the longer side is 660 px, rounded up to 800.
      expect(AppImageCache.decodeWidth(180, 220, 3), 800);
    });

    test('ignores an unbounded side', () {
      expect(AppImageCache.decodeWidth(150, double.infinity, 2), 400);
    });

    test('has no size to give for an unbounded box', () {
      expect(
        AppImageCache.decodeWidth(double.infinity, double.infinity, 3),
        isNull,
      );
    });

    test('never asks for more than 2000 px', () {
      expect(AppImageCache.decodeWidth(1000, 1000, 3), 2000);
    });

    test('a slightly resized box reuses the same decoded size', () {
      expect(
        AppImageCache.decodeWidth(170, 170, 3),
        AppImageCache.decodeWidth(180, 180, 3),
      );
    });
  });
}
