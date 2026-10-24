import 'package:dio/dio.dart';

import 'models/block_status.dart';
import 'models/blocked_account.dart';

/// Blocking other users (`/users/:id/block`). Every change answers the
/// status as the server has it afterwards.
class BlockRepository {
  final Dio dio;

  BlockRepository(this.dio);

  Future<BlockStatus> fetchStatus(String userId) async {
    final response = await dio.get('/users/$userId/block');
    return BlockStatus.fromJson(response.data as Map<String, dynamic>);
  }

  Future<BlockStatus> block(String userId) async {
    final response = await dio.put('/users/$userId/block');
    return BlockStatus.fromJson(response.data as Map<String, dynamic>);
  }

  Future<BlockStatus> unblock(String userId) async {
    final response = await dio.delete('/users/$userId/block');
    return BlockStatus.fromJson(response.data as Map<String, dynamic>);
  }

  /// Everyone the signed-in user blocked, most recently blocked first.
  Future<List<BlockedAccount>> fetchBlocked() async {
    final response = await dio.get('/users/me/blocks');
    return (response.data as List)
        .map((row) => BlockedAccount.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
