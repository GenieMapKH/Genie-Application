import 'package:dio/dio.dart';

import 'package:tilomnov/core/network/api_cache_manager.dart';
import 'package:tilomnov/features/search/data/models/search_history_entry.dart';
import 'package:tilomnov/features/search/data/search_failure.dart';

/// `/search/history`: the signed-in user's searches, kept 14 days by the
/// server and shared by all their devices. Every failure surfaces as a
/// [SearchFailure].
class SearchHistoryRepository {
  final Dio _dio;

  SearchHistoryRepository(this._dio);

  /// Always fresh: another device may have searched since.
  static final _noApiCache = Options(extra: {CacheInterceptor.skipCache: true});

  Future<List<SearchHistoryEntry>> list() => _guard(() async {
    final response = await _dio.get<List<dynamic>>(
      '/search/history',
      options: _noApiCache,
    );
    return (response.data ?? const [])
        .map(
          (item) => SearchHistoryEntry.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  });

  /// The entry as stored: the same text searched before keeps its id.
  Future<SearchHistoryEntry> record(String query) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/search/history',
      data: {'query': query},
    );
    return SearchHistoryEntry.fromJson(response.data!);
  });

  Future<void> remove(String id) => _guard(() async {
    await _dio.delete<void>('/search/history/$id');
  });

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      throw SearchFailure.fromDio(error);
    }
  }
}
