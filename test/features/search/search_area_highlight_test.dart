import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tilomnov/features/search/data/models/search_area.dart';
import 'package:tilomnov/features/search/presentation/widgets/area/search_area_highlight.dart';

void main() {
  test(
    'the mask leaves the searched region clear and dims its surroundings',
    () {
      final clip = SearchAreaOutsideClipper(const [
        Offset(20, 20),
        Offset(20, 80),
        Offset(80, 80),
        Offset(80, 20),
      ]).getClip(const Size(100, 100));
      expect(clip.contains(const Offset(50, 50)), isFalse);
      expect(clip.contains(const Offset(10, 10)), isTrue);
      expect(clip.contains(const Offset(90, 90)), isTrue);
    },
  );
  test(
    'the full place viewport is framed and outlined even without listings',
    () {
      final bounds = LatLngBounds(
        southwest: const LatLng(11.5, 104.8),
        northeast: const LatLng(11.6, 104.9),
      );
      final area = SearchArea(properties: const [], bounds: bounds);
      expect(area.framing, bounds);
      expect(area.outline, [
        bounds.southwest,
        const LatLng(11.6, 104.8),
        bounds.northeast,
        const LatLng(11.5, 104.9),
      ]);
      expect(const SearchArea(properties: []).outline, isEmpty);
    },
  );
}
