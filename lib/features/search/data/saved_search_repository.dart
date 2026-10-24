import 'package:dio/dio.dart';

import 'package:genie/features/property/data/models/map_property_filter.dart';
import 'package:genie/features/property/presentation/view_models/property_providers.dart';

import 'models/saved_search.dart';

/// The server keeps at most this many saved searches per account.
const maxSavedSearches = 20;

/// The server refused to save another: the user already has [maxSavedSearches].
class SavedSearchLimitReached implements Exception {
  const SavedSearchLimitReached();
}

/// The signed-in user's saved map searches (`/search/saved`).
class SavedSearchRepository {
  final Dio dio;

  SavedSearchRepository(this.dio);

  /// Newest first.
  Future<List<SavedSearch>> fetchAll() async {
    final response = await dio.get('/search/saved');
    return (response.data as List)
        .map((row) => SavedSearch.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Throws [SavedSearchLimitReached] when the user has too many already.
  Future<SavedSearch> save({
    required String name,
    required MapBounds area,
    required MapPropertyFilter filter,
  }) async {
    try {
      final response = await dio.post(
        '/search/saved',
        data: SavedSearch.requestBody(name: name, area: area, filter: filter),
      );
      return SavedSearch.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) throw const SavedSearchLimitReached();
      rethrow;
    }
  }

  Future<SavedSearch> update(String id, {String? name, bool? alerts}) async {
    final response = await dio.patch(
      '/search/saved/$id',
      data: {'name': ?name, 'alerts': ?alerts},
    );
    return SavedSearch.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) => dio.delete('/search/saved/$id');
}
