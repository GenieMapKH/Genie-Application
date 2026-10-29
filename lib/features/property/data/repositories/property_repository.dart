import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:tilomnov/core/network/api_cache_manager.dart';
import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:image_picker/image_picker.dart';
import '../models/map_property_filter.dart';
import '../models/property_insights.dart';
import '../models/property_model.dart';

/// One page of the user's own listings, where the next one starts (null
/// after the last), and how many listings they have in each status.
typedef OwnListingsPage = ({
  List<PropertyModel> items,
  int? nextOffset,
  Map<String, int> countByStatus,
});

class PropertyRepository {
  final Dio dio;

  /// For the signed upload links. They carry their own permission, so this
  /// client sends no session token to the storage host.
  final Dio storageDio;

  PropertyRepository(this.dio, {Dio? storageDio})
    : storageDio = storageDio ?? Dio();

  /// Public listings may be reused for a short while without asking the
  /// server; any change the user makes to a property drops them at once.
  static final _publicListings = Options(
    extra: CacheInterceptor.freshFor(const Duration(seconds: 30)),
  );

  /// The signed-in user's own listings per page of the My Properties screen.
  static const ownPageSize = 20;

  /// [limit] of the user's own listings, newest first, from [offset] on,
  /// with how many of them there are in each status. Empty for a session the
  /// server no longer accepts.
  Future<OwnListingsPage> fetchOwnPage({
    required int offset,
    int limit = ownPageSize,
  }) async {
    try {
      final response = await dio.get(
        '/properties',
        queryParameters: {'limit': limit, 'offset': offset},
      );
      final data = response.data as Map<String, dynamic>;
      return (
        items: await compute(
          PropertyModel.listFromJson,
          data['items'] as List<dynamic>,
        ),
        nextOffset: data['nextOffset'] as int?,
        countByStatus: (data['countByStatus'] as Map<String, dynamic>? ?? {})
            .map((status, count) => MapEntry(status, count as int)),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return (
          items: <PropertyModel>[],
          nextOffset: null,
          countByStatus: <String, int>{},
        );
      }
      rethrow;
    }
  }

  /// The user's own listings (drafts too) inside a map area, so the map can
  /// mark them for editing: at most the newest 500.
  Future<List<PropertyModel>> fetchOwnInArea({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    CancelToken? cancelToken,
  }) async {
    final response = await dio.get(
      '/properties/my/in-area',
      queryParameters: {
        'minLat': minLat,
        'maxLat': maxLat,
        'minLng': minLng,
        'maxLng': maxLng,
      },
      cancelToken: cancelToken,
    );
    return compute(PropertyModel.listFromJson, response.data as List<dynamic>);
  }

  /// Published listings inside the given map area that pass [filter]: at
  /// most the newest 500, however large the area.
  Future<List<PropertyModel>> fetchPublicMapProperties({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    MapPropertyFilter filter = const MapPropertyFilter(),
    CancelToken? cancelToken,
  }) async {
    final response = await dio.get(
      '/public/properties/map',
      queryParameters: {
        'minLat': minLat,
        'maxLat': maxLat,
        'minLng': minLng,
        'maxLng': maxLng,
        ...filter.toQueryParameters(),
      },
      // The server keeps this list for 30 s too: going back to an area just
      // seen shows it at once.
      options: _publicListings,
      cancelToken: cancelToken,
    );
    final List<dynamic> data = response.data;
    return compute(PropertyModel.listFromJson, data);
  }

  /// How the asking prices of the listings [fetchPublicMapProperties] would
  /// find spread over equal bars from 0 to [upTo] (the last bar also holds
  /// everything above), ignoring the price range of [filter].
  Future<List<int>> fetchMapPriceHistogram({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    required MapPropertyFilter filter,
    required double upTo,
  }) async {
    final response = await dio.get(
      '/public/properties/map/prices',
      queryParameters: {
        'minLat': minLat,
        'maxLat': maxLat,
        'minLng': minLng,
        'maxLng': maxLng,
        ...filter.withPrice(null, null).toQueryParameters(),
        'upTo': upTo,
      },
      options: _publicListings,
    );
    final counts = (response.data as Map<String, dynamic>)['counts'] as List;
    return [for (final count in counts) (count as num).toInt()];
  }

  Future<PropertyModel> fetchPropertyDetail(String id) async {
    try {
      final response = await dio.get('/properties/$id');
      return PropertyModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        final publicRes = await dio.get(
          '/public/properties/$id',
          options: _publicListings,
        );
        return PropertyModel.fromJson(publicRes.data);
      }
      rethrow;
    }
  }

  Future<PropertyModel> create(Map<String, dynamic> data) async {
    final response = await dio.post('/properties', data: data);
    return PropertyModel.fromJson(response.data);
  }

  /// Changes the listing's details (any field of the create body, keywords
  /// included). Returns it as saved.
  Future<PropertyModel> update(String id, Map<String, dynamic> data) async {
    final response = await dio.patch('/properties/$id', data: data);
    return PropertyModel.fromJson(response.data);
  }

  Future<PropertyModel> updatePin(String id, double lat, double lng) async {
    final response = await dio.patch(
      '/properties/$id/pin',
      data: {'lat': lat, 'lng': lng},
    );
    return PropertyModel.fromJson(response.data);
  }

  Future<PropertyModel> updateBoundary(
    String id,
    List<Map<String, double>> points,
  ) async {
    final response = await dio.patch(
      '/properties/$id/boundary',
      data: {'boundaryPoints': points},
    );
    return PropertyModel.fromJson(response.data);
  }

  /// Takes the photos at [urls] off listing [id]; the server deletes their
  /// files. URLs the listing does not have are ignored.
  Future<PropertyModel> removeImages(String id, List<String> urls) async {
    final response = await dio.post(
      '/properties/$id/images/remove',
      data: {'urls': urls},
    );
    return PropertyModel.fromJson(response.data);
  }

  /// Uploads [images] to [id]: the server hands out one upload link per
  /// picture, in the same order; each picture goes straight to storage; then
  /// the server is told which files arrived.
  Future<PropertyModel> uploadImages(String id, List<XFile> images) async {
    final presignedResponse = await dio.post(
      '/properties/$id/images/presigned-url',
      data: {'fileNames': images.map((image) => image.name).toList()},
    );
    final uploads = (presignedResponse.data as List<dynamic>)
        .cast<Map<String, dynamic>>();

    for (var i = 0; i < images.length && i < uploads.length; i++) {
      final bytes = await images[i].readAsBytes();
      await storageDio.put<void>(
        uploads[i]['signedUrl'] as String,
        data: Stream.fromIterable([bytes]),
        options: Options(
          headers: {
            Headers.contentLengthHeader: bytes.length,
            // Storage only accepts pictures, by their type.
            Headers.contentTypeHeader: images[i].mimeType ?? 'image/jpeg',
          },
        ),
      );
    }

    final response = await dio.post(
      '/properties/$id/images/confirm',
      // The server makes a thumbnail of every photo before it answers.
      options: Options(receiveTimeout: const Duration(seconds: 90)),
      data: {
        'fileNames': [
          for (var i = 0; i < images.length && i < uploads.length; i++)
            uploads[i]['fileName'] as String,
        ],
      },
    );

    return PropertyModel.fromJson(response.data);
  }

  Future<PropertyModel> publish(String id) async {
    final response = await dio.patch('/properties/$id/publish');
    return PropertyModel.fromJson(response.data);
  }

  Future<PropertyModel> unpublish(String id) async {
    final response = await dio.patch('/properties/$id/unpublish');
    return PropertyModel.fromJson(response.data);
  }

  Future<PropertyModel> markSold(String id) async {
    final response = await dio.patch('/properties/$id/mark-sold');
    return PropertyModel.fromJson(response.data);
  }

  Future<PropertyModel> relist(String id) async {
    final response = await dio.patch('/properties/$id/relist');
    return PropertyModel.fromJson(response.data);
  }

  Future<void> remove(String id) async {
    await dio.delete('/properties/$id');
  }

  /// Counts the signed-in user as one viewer of listing [id]. A failure only
  /// leaves the count one short, so it is logged rather than shown.
  Future<void> markAsViewed(String id) async {
    try {
      await dio.post('/properties/$id/view');
    } catch (e) {
      AppLogger.error('Recording a listing view failed', e);
    }
  }

  /// Counts the signed-in user as a lead of listing [id]: they tapped Call
  /// or Chat. The server keeps one per person and channel and ignores the
  /// owner; a failure only leaves the count one short, so it is logged.
  Future<void> recordLead(String id, LeadChannel channel) async {
    try {
      await dio.post('/properties/$id/lead', data: {'channel': channel.name});
    } catch (e) {
      AppLogger.error('Recording a lead failed', e);
    }
  }

  /// How the signed-in owner's listing [id] is doing.
  Future<PropertyInsights> fetchInsights(String id) async {
    final response = await dio.get('/properties/$id/insights');
    return PropertyInsights.fromJson(response.data as Map<String, dynamic>);
  }
}
