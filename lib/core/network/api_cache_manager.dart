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

  Duration get age => DateTime.now().difference(timestamp);

  bool get isExpired => age > ttl;
}

/// In-memory store of API answers for this session, least recently used
/// first. Cleared on sign-out ([clearAll]).
class ApiCacheManager {
  static final ApiCacheManager _instance = ApiCacheManager._internal();
  factory ApiCacheManager() => _instance;
  ApiCacheManager._internal();

  final LinkedHashMap<String, CacheEntry> _cache = LinkedHashMap();
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
    final entry = _cache.remove(key);
    if (entry == null || entry.isExpired) return null;
    // Back to the end: the most recently used entry is removed last.
    _cache[key] = entry;
    return entry;
  }

  /// Put response into cache
  void set(
    String key,
    dynamic data, {
    String? etag,
    Duration ttl = const Duration(minutes: 5),
  }) {
    _cache.remove(key);
    while (_cache.length >= _maxCacheEntries) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = CacheEntry(
      data: data,
      etag: etag,
      timestamp: DateTime.now(),
      ttl: ttl,
    );
  }

  /// Drops every answer about the same resource as [path]: a change under
  /// `/properties/42/favorite` outdates `/properties/my/favorites` and
  /// `/public/properties/map` too, because they all show properties.
  void invalidateResource(String path) {
    final resource = resourceOf(path);
    if (resource == null) return;
    _cache.removeWhere((key, _) => resourceOf(key) == resource);
  }

  /// The first segment of [path] that names what it is about, skipping
  /// `public`: `properties` for `/public/properties/map?minLat=1`.
  static String? resourceOf(String path) {
    final segments = Uri.parse(path).pathSegments.where((s) => s.isNotEmpty);
    return segments.where((s) => s != 'public').firstOrNull;
  }

  /// Wipe entire cache (e.g. on user logout)
  void clearAll() {
    _cache.clear();
  }
}

/// Keeps answers to GET requests (see [ApiCacheManager]):
///
/// * Every answer is kept for a few minutes. Asking again sends its ETag, so
///   an unchanged answer costs the server no body (304), and the kept answer
///   is used when the network is down.
/// * A request marked with [freshFor] is answered from memory, without
///   asking the server, while the kept answer is younger than that. Only for
///   data that may be a few seconds old (public listings, public profiles).
/// * A write (POST, PUT, PATCH, DELETE) drops what is kept about the same
///   resource, before it is sent and again once it is done.
class CacheInterceptor extends Interceptor {
  /// Put `{skipCache: true}` in a request's `extra` to keep it out of this
  /// cache: requests that are rarely repeated (search texts) would only push
  /// useful entries out of the 100 kept.
  static const skipCache = 'skip_api_cache';

  static const _freshForKey = 'api_cache_fresh_for';

  /// `extra` for a request whose kept answer may be reused for [age].
  static Map<String, dynamic> freshFor(Duration age) => {_freshForKey: age};

  final ApiCacheManager _cacheManager = ApiCacheManager();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.extra[skipCache] == true) return handler.next(options);

    if (!_isRead(options)) {
      _cacheManager.invalidateResource(options.path);
      return handler.next(options);
    }

    final key = _cacheManager.buildKey(options.path, options.queryParameters);
    final cached = _cacheManager.get(key);
    if (cached == null) return handler.next(options);

    final freshFor = options.extra[_freshForKey];
    if (freshFor is Duration && cached.age < freshFor) {
      return handler.resolve(_answerFrom(cached, options));
    }

    if (cached.etag != null && cached.etag!.isNotEmpty) {
      options.headers['If-None-Match'] = cached.etag;
    }
    // Kept for onError: a 304 or a network failure answers with it.
    options.extra['cached_entry'] = cached;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final options = response.requestOptions;
    if (options.extra[skipCache] != true) {
      if (!_isRead(options)) {
        // A read answered while this write ran may hold the old data.
        _cacheManager.invalidateResource(options.path);
      } else if (response.statusCode == 200) {
        final key = _cacheManager.buildKey(
          options.path,
          options.queryParameters,
        );
        final etag = response.headers.value('etag');
        _cacheManager.set(key, response.data, etag: etag);
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final cached = err.requestOptions.extra['cached_entry'] as CacheEntry?;
    final notModified = err.response?.statusCode == 304;
    final offline =
        err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout;

    if (cached != null && (notModified || offline)) {
      return handler.resolve(_answerFrom(cached, err.requestOptions));
    }
    handler.next(err);
  }

  static bool _isRead(RequestOptions options) =>
      options.method.toUpperCase() == 'GET';

  static Response _answerFrom(CacheEntry cached, RequestOptions options) =>
      Response(requestOptions: options, statusCode: 200, data: cached.data);
}
