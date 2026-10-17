import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/property_model.dart';

List<PropertyModel> _parseProperties(List<dynamic> data) {
  return data.map((json) => PropertyModel.fromJson(json)).toList();
}

class PropertyRepository {
  final Dio dio;

  PropertyRepository(this.dio);

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

  Future<List<PropertyModel>> fetchPublicMapProperties({
    double minLat = -90,
    double maxLat = 90,
    double minLng = -180,
    double maxLng = 180,
  }) async {
    final response = await dio.get(
      '/public/properties/map',
      queryParameters: {
        'minLat': minLat,
        'maxLat': maxLat,
        'minLng': minLng,
        'maxLng': maxLng,
      },
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
        final publicRes = await dio.get('/public/properties/$id');
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

  Future<PropertyModel> uploadImages(String id, List<XFile> images) async {
    // 1. Get presigned URLs
    final fileNames = images.map((i) => i.name).toList();
    final presignedResponse = await dio.post(
      '/properties/$id/images/presigned-url',
      data: {'fileNames': fileNames},
    );

    final List<dynamic> presignedData = presignedResponse.data;

    // 2. Upload directly to Supabase Storage
    for (int i = 0; i < images.length; i++) {
      final image = images[i];
      final urlData = presignedData.firstWhere(
        (d) => d['fileName'].toString().endsWith(image.name),
        orElse: () => null,
      );
      if (urlData != null) {
        final signedUrl = urlData['signedUrl'];
        final bytes = await image.readAsBytes();

        final dioUpload = Dio(); // Use new Dio instance to avoid interceptors
        await dioUpload.put(
          signedUrl,
          data: bytes,
          options: Options(
            headers: {
              'Content-Type':
                  'application/octet-stream', // Supabase requires content-type
            },
          ),
        );
      }
    }

    // 3. Confirm upload
    final uploadedFileNames = presignedData
        .map((d) => d['fileName'].toString())
        .toList();
    final response = await dio.post(
      '/properties/$id/images/confirm',
      data: {'fileNames': uploadedFileNames},
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

  Future<void> remove(String id) async {
    await dio.delete('/properties/$id');
    _cachedProperties.removeWhere((p) => p.id == id);
  }

  Future<void> markAsViewed(String id) async {
    try {
      await dio.post('/properties/$id/view');
    } catch (e) {
      // Ignore errors for tracking views
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
