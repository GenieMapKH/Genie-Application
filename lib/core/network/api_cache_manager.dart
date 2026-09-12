import 'dart:collection';
import 'package:dio/dio.dart';

class CacheEntry {
  final dynamic data;
  final String? etag;
  final DateTime timestamp;
  final Duration ttl;

  CacheEntry({
    required this.data,
    this.etag,
    required this.timestamp,
    required this.ttl,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > ttl;
}

/// In-memory & response cache manager for API calls.
class ApiCacheManager {
  static final ApiCacheManager _instance = ApiCacheManager._internal();
  factory ApiCacheManager() => _instance;
  ApiCacheManager._internal();

  final Map<String, CacheEntry> _cache = HashMap();
  static const int _maxCacheEntries = 100;

  /// Generate unique cache key from path and query parameters
  String buildKey(String path, [Map<String, dynamic>? queryParameters]) {
    if (queryParameters == null || queryParameters.isEmpty) {
      return path;
    }
    final sortedKeys = queryParameters.keys.toList()..sort();
    final queryString = sortedKeys
        .map((k) => '$k=${queryParameters[k]}')
        .join('&');
    return '$path?$queryString';
  }

  /// Get cached response if valid
  CacheEntry? get(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    return entry;
  }

  /// Put response into cache
  void set(
    String key,
    dynamic data, {
    String? etag,
    Duration ttl = const Duration(minutes: 5),
  }) {
    if (_cache.length >= _maxCacheEntries) {
      // Remove oldest entry
      final firstKey = _cache.keys.first;
      _cache.remove(firstKey);
    }
    _cache[key] = CacheEntry(
      data: data,
      etag: etag,
      timestamp: DateTime.now(),
      ttl: ttl,
    );
  }

  /// Invalidate specific key or keys matching prefix pattern
  void invalidate(String pattern) {
    _cache.removeWhere((key, _) => key.contains(pattern));
  }

  /// Wipe entire cache (e.g. on user logout)
  void clearAll() {
    _cache.clear();
  }
}

/// Dio Interceptor for automatic HTTP GET response caching & ETag support
class CacheInterceptor extends Interceptor {
  final ApiCacheManager _cacheManager = ApiCacheManager();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Only cache GET requests
    if (options.method.toUpperCase() != 'GET') {
      // Invalidate write operations (POST, PUT, DELETE, PATCH)
      _cacheManager.invalidate(options.path);
      return handler.next(options);
    }

    final key = _cacheManager.buildKey(options.path, options.queryParameters);
    final cached = _cacheManager.get(key);

    if (cached != null) {
      // Attach If-None-Match header if ETag is available
      if (cached.etag != null && cached.etag!.isNotEmpty) {
        options.headers['If-None-Match'] = cached.etag;
      }

      // Store cached data in extra so onResponse / onError can utilize it
      options.extra['cached_entry'] = cached;
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.requestOptions.method.toUpperCase() == 'GET' &&
        response.statusCode == 200) {
      final key = _cacheManager.buildKey(
        response.requestOptions.path,
        response.requestOptions.queryParameters,
      );
      final etag = response.headers.value('etag');
      _cacheManager.set(key, response.data, etag: etag);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // If backend returns 304 Not Modified, fulfill request with cached data
    if (err.response?.statusCode == 304) {
      final cached = err.requestOptions.extra['cached_entry'] as CacheEntry?;
      if (cached != null) {
        final response = Response(
          requestOptions: err.requestOptions,
          statusCode: 200,
          data: cached.data,
        );
        return handler.resolve(response);
      }
    }

    // Network failure / Offline fallback to cached data if available
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout) {
      final cached = err.requestOptions.extra['cached_entry'] as CacheEntry?;
      if (cached != null) {
        final response = Response(
          requestOptions: err.requestOptions,
          statusCode: 200,
          data: cached.data,
        );
        return handler.resolve(response);
      }
    }

    handler.next(err);
  }
}
