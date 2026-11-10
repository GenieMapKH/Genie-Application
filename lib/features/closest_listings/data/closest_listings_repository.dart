import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:tilomnov/core/storage/kept_copy_store.dart';

import 'package:tilomnov/features/closest_listings/data/closest_listing.dart';
import 'package:tilomnov/features/property/data/models/map_property_filter.dart';

/// One page of listings by distance, and where the next one starts (null
/// after the last).
typedef ClosestListingsPage = ({List<ClosestListing> items, int? nextOffset});

/// Every published listing nearest to a point first
/// (`/public/properties/closest`), passing the map filter.
class ClosestListingsRepository {
  final Dio dio;

  /// The first page as last read, with the filter it passed
  /// ([keptFirstPage]). Public listings: one copy for the device.
  final KeptCopyStore _kept;
  static const _keptName = 'closest.first_page.v1';

  /// Listings per page.
  static const pageSize = 20;

  ClosestListingsRepository(this.dio, {KeptCopyStore? kept})
    : _kept = kept ?? KeptCopyStore(account: () async => 'device');

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
    if (offset == 0) {
      await _kept.write(_keptName, {
        'filter': _filterKey(filter),
        'page': data,
      });
    }
    return _pageOf(data);
  }

  /// The first page as last read on this device, if it was read with
  /// [filter]; null otherwise.
  Future<ClosestListingsPage?> keptFirstPage(MapPropertyFilter filter) =>
      _kept.read<ClosestListingsPage?>(
        _keptName,
        parse: (json) async => json['filter'] == _filterKey(filter)
            ? await _pageOf(json['page'] as Map<String, dynamic>)
            : null,
      );

  static String _filterKey(MapPropertyFilter filter) => Uri(
    queryParameters: {
      for (final MapEntry(:key, :value) in filter.toQueryParameters().entries)
        key: '$value',
    },
  ).query;

  static Future<ClosestListingsPage> _pageOf(Map<String, dynamic> data) async =>
      (
        items: await compute(
          ClosestListing.listFromJson,
          data['items'] as List<dynamic>,
        ),
        nextOffset: (data['nextOffset'] as num?)?.toInt(),
      );
}
