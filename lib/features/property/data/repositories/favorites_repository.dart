import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:tilomnov/core/storage/kept_copy_store.dart';
import 'package:tilomnov/features/auth/data/datasources/auth_local_data_source.dart';

import '../models/property_model.dart';

/// How the server orders saved listings (`sort` of `/properties/my/favorites`).
enum FavoriteSort { saved, newest, priceHigh, priceLow }

/// One page of saved listings, and where the next one starts (null after
/// the last).
typedef FavoritesPage = ({List<PropertyModel> items, int? nextOffset});

/// The signed-in user's saved listings: which ones (for the hearts), a page
/// of them (for the Saved screen), and saving or unsaving one.
class FavoritesRepository {
  final Dio dio;

  /// The first page in each order, kept for the signed-in account by
  /// default ([keptFirstPage]).
  final KeptCopyStore _kept;

  /// Listings per page of the Saved screen.
  static const pageSize = 20;

  FavoritesRepository(this.dio, {Future<String?> Function()? accountId})
    : _kept = KeptCopyStore(account: accountId ?? AuthStorage.signedInUserId);

  static String _keptName(FavoriteSort sort) =>
      'saved.first_page.v1.${sort.name}';

  /// The ids of every saved listing, most recently saved first. None for a
  /// session the server no longer accepts.
  Future<List<String>> fetchIds() async {
    try {
      final response = await dio.get('/properties/my/favorites/ids');
      return (response.data as List).cast<String>();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return [];
      rethrow;
    }
  }

  /// [limit] saved listings from [offset] on, in [sort] order.
  Future<FavoritesPage> fetchPage({
    required int offset,
    required FavoriteSort sort,
    int limit = pageSize,
  }) async {
    final response = await dio.get(
      '/properties/my/favorites',
      queryParameters: {'limit': limit, 'offset': offset, 'sort': sort.name},
    );
    final data = response.data as Map<String, dynamic>;
    if (offset == 0) await _kept.write(_keptName(sort), data);
    return _pageOf(data);
  }

  /// The first page in [sort] order as last read on this device, or null.
  Future<FavoritesPage?> keptFirstPage(FavoriteSort sort) =>
      _kept.read(_keptName(sort), parse: _pageOf);

  static Future<FavoritesPage> _pageOf(Map<String, dynamic> data) async => (
    items: await compute(
      PropertyModel.listFromJson,
      data['items'] as List<dynamic>,
    ),
    nextOffset: data['nextOffset'] as int?,
  );

  Future<void> favorite(String id) async {
    await dio.post('/properties/$id/favorite');
  }

  Future<void> unfavorite(String id) async {
    await dio.delete('/properties/$id/favorite');
  }
}
