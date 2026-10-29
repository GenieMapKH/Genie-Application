import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';

import 'feed_cache.dart';

/// One page of the feed, and the cursor of the next (null after the last).
typedef FeedListingsPage = ({List<PropertyModel> items, String? nextCursor});

/// The feed (`/feed`): live listings of the people the signed-in user
/// follows, most recently published first. The first page is also kept on
/// the device ([savedFirstPage]).
class FeedRepository {
  final Dio dio;
  final FeedCache _cache;

  /// Whose feed is kept; the signed-in account by default.
  final Future<String?> Function() _accountId;

  /// Listings per page.
  static const pageSize = 20;

  FeedRepository(
    this.dio, {
    FeedCache? cache,
    Future<String?> Function()? accountId,
  }) : _cache = cache ?? FeedCache(),
       _accountId = accountId ?? AuthStorage.signedInUserId;

  /// [limit] listings after [cursor] (`nextCursor` of the page before), or
  /// from the start. The first page is kept for [savedFirstPage].
  Future<FeedListingsPage> fetchPage({
    String? cursor,
    int limit = pageSize,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/feed',
      queryParameters: {'limit': limit, 'cursor': ?cursor},
    );
    final data = response.data!;
    if (cursor == null) await _keep(data);
    return _pageOf(data);
  }

  /// The first page as last read for this account, or null when none is
  /// kept (or it can no longer be read).
  Future<FeedListingsPage?> savedFirstPage() async {
    final userId = await _accountId();
    if (userId == null) return null;
    final json = await _cache.read(userId);
    if (json == null) return null;
    try {
      return await _pageOf(jsonDecode(json) as Map<String, dynamic>);
    } catch (e) {
      // A page kept by an older build: the fresh one replaces it.
      AppLogger.error('The kept feed page could not be read', e);
      return null;
    }
  }

  Future<void> _keep(Map<String, dynamic> data) async {
    final userId = await _accountId();
    if (userId != null) await _cache.write(userId, jsonEncode(data));
  }

  static Future<FeedListingsPage> _pageOf(Map<String, dynamic> data) async {
    return (
      items: await compute(
        PropertyModel.listFromJson,
        data['items'] as List<dynamic>,
      ),
      nextCursor: data['nextCursor'] as String?,
    );
  }
}
