import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:genie/core/network/api_cache_manager.dart';
import 'package:genie/core/logging/app_logger.dart';
import 'package:image_picker/image_picker.dart';
import '../models/property_model.dart';

List<PropertyModel> _parseProperties(List<dynamic> data) {
  return data.map((json) => PropertyModel.fromJson(json)).toList();
}

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

  // Cache for client-side filtering
  List<PropertyModel> _cachedProperties = [];

  Future<List<PropertyModel>> fetchAll({bool forceRefresh = false}) async {
    if (_cachedProperties.isNotEmpty && !forceRefresh) {
      return _cachedProperties;
    }

    // In guest mode (no token), fetching /properties will return 401.
    // We catch it and return empty list.
    try {
      final response = await dio.get('/properties');
      final List<dynamic> data = response.data;
      _cachedProperties = await compute(_parseProperties, data);
      return _cachedProperties;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _cachedProperties = [];
        return [];
      }
      rethrow;
    }
  }

  /// Published listings inside the given map area, of [propertyType] and
  /// [listingType] when given: at most the newest 500, however large the area.
  Future<List<PropertyModel>> fetchPublicMapProperties({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    String? propertyType,
    String? listingType,
  }) async {
    final response = await dio.get(
      '/public/properties/map',
      queryParameters: {
        'minLat': minLat,
        'maxLat': maxLat,
        'minLng': minLng,
        'maxLng': maxLng,
        'propertyType': ?propertyType,
        'listingType': ?listingType,
      },
      // The server keeps this list for 30 s too: going back to an area just
      // seen shows it at once.
      options: _publicListings,
    );
    final List<dynamic> data = response.data;
    return compute(_parseProperties, data);
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

  List<PropertyModel> getPropertiesByStatus(String status) {
    return _cachedProperties.where((p) => p.status == status).toList();
  }

  Future<PropertyModel> create(Map<String, dynamic> data) async {
    final response = await dio.post('/properties', data: data);
    final property = PropertyModel.fromJson(response.data);
    _cachedProperties.insert(0, property);
    return property;
  }

  /// Changes the listing's details (any field of the create body, keywords
  /// included). Returns it as saved.
  Future<PropertyModel> update(String id, Map<String, dynamic> data) async {
    final response = await dio.patch('/properties/$id', data: data);
    final property = PropertyModel.fromJson(response.data);
    final index = _cachedProperties.indexWhere((p) => p.id == id);
    if (index != -1) _cachedProperties[index] = property;
    return property;
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
    _refreshCache();
    return PropertyModel.fromJson(response.data);
  }

  /// Takes the photos at [urls] off listing [id]; the server deletes their
  /// files. URLs the listing does not have are ignored.
  Future<PropertyModel> removeImages(String id, List<String> urls) async {
    final response = await dio.post(
      '/properties/$id/images/remove',
      data: {'urls': urls},
    );
    _refreshCache();
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
      data: {
        'fileNames': [
          for (var i = 0; i < images.length && i < uploads.length; i++)
            uploads[i]['fileName'] as String,
        ],
      },
    );

    _refreshCache();
    return PropertyModel.fromJson(response.data);
  }

  Future<PropertyModel> publish(String id) async {
    final response = await dio.patch('/properties/$id/publish');
    _refreshCache();
    return PropertyModel.fromJson(response.data);
  }

  Future<PropertyModel> unpublish(String id) async {
    final response = await dio.patch('/properties/$id/unpublish');
    _refreshCache();
    return PropertyModel.fromJson(response.data);
  }

  Future<PropertyModel> markSold(String id) async {
    final response = await dio.patch('/properties/$id/mark-sold');
    _refreshCache();
    return PropertyModel.fromJson(response.data);
  }

  Future<PropertyModel> relist(String id) async {
    final response = await dio.patch('/properties/$id/relist');
    _refreshCache();
    return PropertyModel.fromJson(response.data);
  }

  Future<void> remove(String id) async {
    await dio.delete('/properties/$id');
    _cachedProperties.removeWhere((p) => p.id == id);
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

  Future<List<PropertyModel>> fetchFavorites() async {
    try {
      final response = await dio.get('/properties/my/favorites');
      final List<dynamic> data = response.data;
      return await compute(_parseProperties, data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return [];
      }
      rethrow;
    }
  }

  Future<void> favorite(String id) async {
    await dio.post('/properties/$id/favorite');
  }

  Future<void> unfavorite(String id) async {
    await dio.delete('/properties/$id/favorite');
  }

  void invalidateCache() {
    _cachedProperties = [];
  }

  Future<void> _refreshCache() async {
    await fetchAll(forceRefresh: true);
  }
}
