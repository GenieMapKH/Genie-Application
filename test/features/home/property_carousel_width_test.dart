import 'package:flutter_test/flutter_test.dart';

import 'package:tilomnov/features/home/presentation/widgets/map/property_carousel.dart';

void main() {
  test('a phone keeps the wide card', () {
    expect(PropertyCarousel.viewportFractionFor(390), 0.88);
  });

  test('a landscape tablet keeps cards phone-sized', () {
    final fraction = PropertyCarousel.viewportFractionFor(1600);
    expect(fraction * 1600, closeTo(400, 0.01));
  });

  test('no width yet falls back to the phone share', () {
    expect(PropertyCarousel.viewportFractionFor(0), 0.88);
  });
}
