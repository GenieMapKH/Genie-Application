import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:genie/core/network/api_cache_manager.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/search/data/models/place_suggestion.dart';
import 'package:genie/features/search/data/models/publisher_profile.dart';
import 'package:genie/features/search/data/models/publisher_summary.dart';
import 'package:genie/features/search/data/models/search_area.dart';
import 'package:genie/features/search/data/models/search_results.dart';
import 'package:genie/features/search/data/search_failure.dart';
import 'package:genie/features/search/data/search_results_cache.dart';

/// `/public/search`: one request per text answers places, listings and
/// people together. Every failure surfaces as a [SearchFailure].
class SearchRepository {
  final Dio _dio;
  final SearchResultsCache _cache;

  SearchRepository(this._dio, {SearchResultsCache? cache})
    : _cache = cache ?? SearchResultsCache();

  static final _noApiCache = Options(extra: {CacheInterceptor.skipCache: true});

  /// A recent answer for [normalizedText], without asking the server.
  SearchResults? cached(String normalizedText, String language) =>
      _cache.get(_key(normalizedText, language));

  /// [normalizedText] comes from `SearchText.normalize`. Cancelling
  /// [cancelToken] (a newer text arrived) throws a cancelled [DioException]
  /// instead of a [SearchFailure], so callers can tell it apart.
  Future<SearchResults> search(
    String normalizedText, {
    required String language,
    String? sessionToken,
    LatLng? near,
    CancelToken? cancelToken,
  }) async {
    final cached = this.cached(normalizedText, language);
    if (cached != null) return cached;

    final data = await _get('/public/search', {
      'q': normalizedText,
      'lang': language,
      'session': ?sessionToken,
      if (near != null) ...{
        'lat': near.latitude.toStringAsFixed(4),
        'lng': near.longitude.toStringAsFixed(4),
      },
    }, cancelToken: cancelToken);
    final results = SearchResults.fromJson(data);
    _cache.put(_key(normalizedText, language), results);
    return results;
  }

  /// The place's map region and the published listings inside it.
  Future<SearchArea> placeArea(
    PlaceSuggestion place, {
    required String language,
    String? sessionToken,
  }) async {
    final data = await _get(
      '/public/search/places/${Uri.encodeComponent(place.placeId)}',
      {'lang': language, 'session': ?sessionToken},
    );
    final viewport =
        (data['place'] as Map<String, dynamic>)['viewport']
            as Map<String, dynamic>;

    return SearchArea(
      properties: await _parseProperties(data['properties']),
      bounds: LatLngBounds(
        southwest: LatLng(
          (viewport['minLat'] as num).toDouble(),
          (viewport['minLng'] as num).toDouble(),
        ),
        northeast: LatLng(
          (viewport['maxLat'] as num).toDouble(),
          (viewport['maxLng'] as num).toDouble(),
        ),
      ),
    );
  }

  /// Someone who posts listings, as their public profile shows them, with
  /// their published listings, newest first.
  Future<PublisherProfile> publisherProfile(String userId) async {
    final data = await _get('/public/search/people/$userId', const {});
    return PublisherProfile(
      person: PublisherSummary.fromJson(data['person'] as Map<String, dynamic>),
      properties: await _parseProperties(data['properties']),
    );
  }

  /// The person's published listings, framed together on the map.
  Future<SearchArea> publisherArea(PublisherSummary person) async {
    final profile = await publisherProfile(person.id);
    return SearchArea.around(profile.properties);
  }

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, dynamic> query, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: query,
        options: _noApiCache,
        cancelToken: cancelToken,
      );
      return response.data ?? const {};
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) rethrow;
      throw SearchFailure.fromDio(error);
    }
  }

  /// Below this many listings, starting an isolate costs more than parsing.
  static const _parseInBackgroundFrom = 20;

  /// An area can hold up to a hundred listings with all their photos: a long
  /// list is parsed off the UI thread so the panel opens without a dropped
  /// frame.
  static Future<List<PropertyModel>> _parseProperties(Object? raw) {
    final list = raw as List<dynamic>? ?? const [];
    if (list.length < _parseInBackgroundFrom) return Future.value(_parse(list));
    return compute(_parse, list);
  }

  static List<PropertyModel> _parse(List<dynamic> list) => list
      .map((item) => PropertyModel.fromJson(item as Map<String, dynamic>))
      .toList();

  static String _key(String text, String language) => '$language:$text';
}
