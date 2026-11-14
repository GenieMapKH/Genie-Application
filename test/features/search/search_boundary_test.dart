import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tilomnov/features/search/data/models/place_suggestion.dart';
import 'package:tilomnov/features/search/data/models/search_area.dart';
import 'package:tilomnov/features/search/data/models/search_boundary.dart';
import 'package:tilomnov/features/search/data/search_repository.dart';

import '../../support/test_app.dart';

const _boundary = {
  'type': 'MultiPolygon',
  'coordinates': [
    [
      [
        [104.8, 11.5],
        [104.9, 11.5],
        [104.85, 11.6],
        [104.8, 11.5],
      ],
      [
        [104.84, 11.53],
        [104.86, 11.53],
        [104.85, 11.55],
        [104.84, 11.53],
      ],
    ],
    [
      [
        [104.91, 11.5],
        [104.93, 11.5],
        [104.92, 11.52],
        [104.91, 11.5],
      ],
    ],
  ],
};

void main() {
  test(
    'keeps the actual shape, islands and holes in latitude/longitude order',
    () {
      final boundaries = SearchBoundary.fromJson(_boundary);
      expect(boundaries, hasLength(2));
      expect(boundaries.first.points[2], const LatLng(11.6, 104.85));
      expect(boundaries.first.holes.single[1], const LatLng(11.53, 104.86));
      expect(boundaries.last.points.first, const LatLng(11.5, 104.91));
    },
  );

  test(
    'missing or malformed geometry never becomes a rectangle or partial shape',
    () {
      expect(SearchBoundary.fromJson(null), isEmpty);
      expect(SearchBoundary.fromJson({'type': 'Polygon'}), isEmpty);
      expect(
        SearchBoundary.fromJson({
          'type': 'MultiPolygon',
          'coordinates': [
            [
              [
                [104, 11],
                [104, 12],
                [105, 12],
                [106, 13],
              ],
            ],
          ],
        }),
        isEmpty,
      );
      expect(
        SearchBoundary.fromJson({
          'type': 'MultiPolygon',
          'coordinates': [
            [
              [
                [104, 11],
                [104, 12],
                [200, 12],
                [104, 11],
              ],
            ],
          ],
        }),
        isEmpty,
      );
      final bounds = LatLngBounds(
        southwest: const LatLng(11.5, 104.8),
        northeast: const LatLng(11.6, 104.9),
      );
      final area = SearchArea(properties: const [], bounds: bounds);
      expect(area.framing, bounds);
      expect(area.boundaries, isEmpty);
    },
  );

  test(
    'the place API supplies mapped shapes and remains compatible with older servers',
    () async {
      for (final geometry in [_boundary, null]) {
        final repository = SearchRepository(
          StubServer.always(
            200,
            jsonEncode({
              'place': {
                'viewport': {
                  'minLat': 11.5,
                  'maxLat': 11.6,
                  'minLng': 104.8,
                  'maxLng': 104.93,
                },
                'boundary': ?geometry,
              },
              'properties': [],
            }),
          ).dio,
        );
        final area = await repository.placeArea(
          const PlaceSuggestion(placeId: 'area', primaryText: 'Area'),
          language: 'km',
        );
        expect(area.boundaries, hasLength(geometry == null ? 0 : 2));
        expect(area.framing!.northeast, const LatLng(11.6, 104.93));
      }
    },
  );
}
