import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:tilomnov/features/closest_listings/data/closest_listing.dart';
import 'package:tilomnov/features/property/data/models/map_property_filter.dart';

/// One page of listings by distance, and where the next one starts (null
/// after the last).
typedef ClosestListingsPage = ({List<ClosestListing> items, int? nextOffset});

/// Every published listing nearest to a point first
/// (`/public/properties/closest`), passing the map filter.
class ClosestListingsRepository {
  final Dio dio;

  /// Listings per page.
  static const pageSize = 20;

  ClosestListingsRepository(this.dio);

  /// [limit] listings after the first [offset], nearest to [origin] first.
  Future<ClosestListingsPage> fetchPage({
    required LatLng origin,
    MapPropertyFilter filter = const MapPropertyFilter(),
    int offset = 0,
    int limit = pageSize,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/public/properties/closest',
      queryParameters: {
        'lat': origin.latitude,
        'lng': origin.longitude,
        'limit': limit,
        'offset': offset,
        ...filter.toQueryParameters(),
      },
    );
    final data = response.data!;
    return (
      items: await compute(
        ClosestListing.listFromJson,
        data['items'] as List<dynamic>,
      ),
      nextOffset: (data['nextOffset'] as num?)?.toInt(),
    );
  }
}
