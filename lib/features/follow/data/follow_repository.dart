import 'package:dio/dio.dart';

import 'models/follow_summary.dart';

/// The server refused a follow: the user already follows [limit] people.
class FollowLimitReached implements Exception {
  /// The most people one account may follow (the server's limit).
  static const limit = 500;

  const FollowLimitReached();
}

/// Following other users (`/users/:id/follow`). Every call answers the
/// person's counts as the server has them afterwards.
class FollowRepository {
  final Dio dio;

  FollowRepository(this.dio);

  Future<FollowSummary> fetchSummary(String userId) async {
    final response = await dio.get('/users/$userId/follow');
    return FollowSummary.fromJson(response.data as Map<String, dynamic>);
  }

  /// Throws [FollowLimitReached] when the user follows too many people.
  Future<FollowSummary> follow(String userId) async {
    try {
      final response = await dio.put('/users/$userId/follow');
      return FollowSummary.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) throw const FollowLimitReached();
      rethrow;
    }
  }

  Future<FollowSummary> unfollow(String userId) async {
    final response = await dio.delete('/users/$userId/follow');
    return FollowSummary.fromJson(response.data as Map<String, dynamic>);
  }
}
