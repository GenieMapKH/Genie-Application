import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/data/repositories/property_repository.dart';
import 'package:tilomnov/features/property/presentation/view_models/add_property_controller.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_form_input.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_providers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../support/test_app.dart';

final _listingJson = {
  'id': 'p-1',
  'title': 'Land',
  'price': '1',
  'propertyType': 'Land',
  'status': 'Active',
  'createdAt': '2026-10-01T00:00:00.000Z',
  'images': [],
};

/// The writes the edit made, as "METHOD path".
List<String> _writes(StubServer api) => [
  for (final r in api.requests)
    if (r.method != 'GET') '${r.method} ${r.path}',
];

Future<StubServer> _saveEdit({
  List<LatLng>? boundaryPoints,
  List<String> removedPhotoUrls = const [],
}) async {
  // Saving a boundary also reloads the owner's listings in the background.
  final api = StubServer(
    (request) =>
        request.method == 'GET' ? (200, '[]') : (200, jsonEncode(_listingJson)),
  );
  final container = ProviderContainer(
    overrides: [
      propertyRepositoryProvider.overrideWithValue(PropertyRepository(api.dio)),
    ],
  );
  addTearDown(container.dispose);
  final subscription = container.listen(
    addPropertyControllerProvider,
    (_, _) {},
  );
  addTearDown(subscription.close);

  await container
      .read(addPropertyControllerProvider.notifier)
      .updateProperty(
        propertyId: 'p-1',
        input: PropertyFormInput.fromProperty(
          PropertyModel.fromJson(_listingJson),
        ),
        newPhotos: const [],
        boundaryPoints: boundaryPoints,
        removedPhotoUrls: removedPhotoUrls,
      );
  return api;
}

void main() {
  test(
    'saving an edit with a redrawn boundary saves the boundary too',
    () async {
      final api = await _saveEdit(
        boundaryPoints: const [LatLng(0, 0), LatLng(0, 1), LatLng(1, 1)],
      );

      expect(_writes(api), [
        'PATCH /properties/p-1',
        'PATCH /properties/p-1/boundary',
      ]);
      expect(api.requests.firstWhere((r) => r.path.endsWith('boundary')).body, {
        'boundaryPoints': [
          {'lat': 0.0, 'lng': 0.0},
          {'lat': 0.0, 'lng': 1.0},
          {'lat': 1.0, 'lng': 1.0},
        ],
      });
    },
  );

  test('saving an edit without a new boundary leaves it alone', () async {
    final api = await _saveEdit();

    expect(_writes(api), ['PATCH /properties/p-1']);
  });

  test('saving an edit takes off the photos removed in it', () async {
    final api = await _saveEdit(removedPhotoUrls: ['https://cdn.test/a.jpg']);

    expect(_writes(api), [
      'PATCH /properties/p-1',
      'POST /properties/p-1/images/remove',
    ]);
    expect(api.requests.firstWhere((r) => r.path.endsWith('remove')).body, {
      'urls': ['https://cdn.test/a.jpg'],
    });
  });
}
