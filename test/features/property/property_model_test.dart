import 'package:flutter_test/flutter_test.dart';

import 'package:genie/features/property/data/models/property_model.dart';

void main() {
  group('fromJson', () {
    test('parses the owner name and counts from the map endpoint', () {
      final property = PropertyModel.fromJson({
        'id': 'abc',
        'title': 'Near Ring Road 3',
        'price': '105400',
        'propertyType': 'Land',
        'status': 'Active',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'landSize': '1670',
        'user': {'username': 'Pisal'},
        '_count': {'favorites': 99, 'views': 1688, 'contacts': 5},
      });

      expect(property.ownerName, 'Pisal');
      expect(property.saveCount, 99);
      expect(property.viewCount, 1688);
      expect(property.contactCount, 5);
      expect(property.landSize, 1670);
    });

    test('cards show thumbnails, falling back to the photo without one', () {
      final property = PropertyModel.fromJson({
        'id': 'abc',
        'title': 'Villa',
        'price': '1000',
        'propertyType': 'Villa',
        'status': 'Active',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'images': [
          {
            'url': 'https://s/a.jpg',
            'thumbnailUrl': 'https://s/a.jpg.thumb.jpg',
          },
          {'url': 'https://s/old.jpg', 'thumbnailUrl': null},
          {'url': 'https://s/older.jpg'},
        ],
      });

      expect(property.imageUrls, [
        'https://s/a.jpg',
        'https://s/old.jpg',
        'https://s/older.jpg',
      ]);
      expect(property.cardImageUrls, [
        'https://s/a.jpg.thumb.jpg',
        'https://s/old.jpg',
        'https://s/older.jpg',
      ]);
    });

    test('cards show the full photos when the lists disagree', () {
      final property = PropertyModel(
        id: 'abc',
        title: 'Villa',
        price: '1000',
        propertyType: 'Villa',
        status: 'Active',
        createdAt: DateTime(2026),
        imageUrls: const ['a.jpg', 'b.jpg'],
        thumbnailUrls: const ['a.thumb.jpg'],
      );

      expect(property.cardImageUrls, ['a.jpg', 'b.jpg']);
    });

    test('defaults gracefully when the owner and counts are absent', () {
      final property = PropertyModel.fromJson({
        'id': 'abc',
        'title': 'Untitled',
        'price': '1000',
        'propertyType': 'Land',
        'status': 'Active',
        'createdAt': '2026-01-01T00:00:00.000Z',
      });

      expect(property.ownerName, isNull);
      expect(property.saveCount, 0);
      expect(property.viewCount, 0);
      expect(property.contactCount, 0);
    });

    test('parses boundary points supplied as a JSON string', () {
      final property = PropertyModel.fromJson({
        'id': 'abc',
        'title': 'Bounded',
        'price': '1000',
        'propertyType': 'Land',
        'status': 'Active',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'boundaryPoints':
            '[{"lat":11.5,"lng":104.9},{"lat":11.6,"lng":104.9},{"lat":11.6,"lng":105.0}]',
      });

      expect(property.boundaryPoints, hasLength(3));
      expect(property.boundaryPoints.first.latitude, 11.5);
    });

    test('maps image objects to their urls in order', () {
      final property = PropertyModel.fromJson({
        'id': 'abc',
        'title': 'With photos',
        'price': '1000',
        'propertyType': 'Land',
        'status': 'Active',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'images': [
          {'url': 'https://example.com/1.jpg'},
          {'url': 'https://example.com/2.jpg'},
        ],
      });

      expect(property.imageUrls, [
        'https://example.com/1.jpg',
        'https://example.com/2.jpg',
      ]);
    });
  });

  group('copyWith', () {
    test('preserves the new fields when copying', () {
      final original = PropertyModel(
        id: 'abc',
        title: 'Original',
        price: '1000',
        propertyType: 'Land',
        status: 'Active',
        createdAt: DateTime(2026, 1, 1),
        ownerName: 'Pisal',
        saveCount: 12,
        viewCount: 40,
        contactCount: 3,
      );

      final copy = original.copyWith(status: 'Draft');

      expect(copy.status, 'Draft');
      expect(copy.ownerName, 'Pisal');
      expect(copy.saveCount, 12);
      expect(copy.viewCount, 40);
      expect(copy.contactCount, 3);
    });
  });
}
