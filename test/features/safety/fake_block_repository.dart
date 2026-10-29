import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/features/safety/data/block_repository.dart';
import 'package:tilomnov/features/safety/data/models/block_status.dart';
import 'package:tilomnov/features/safety/data/models/blocked_account.dart';
import 'package:tilomnov/features/safety/presentation/view_models/block_providers.dart';

/// Answers at once from memory: nobody is blocked unless [status] says so.
class FakeBlockRepository extends BlockRepository {
  BlockStatus status;
  final List<String> calls = [];

  FakeBlockRepository({
    this.status = const BlockStatus(isBlocked: false, canMessage: true),
  }) : super(Dio());

  @override
  Future<BlockStatus> fetchStatus(String userId) async {
    calls.add('status $userId');
    return status;
  }

  @override
  Future<BlockStatus> block(String userId) async {
    calls.add('block $userId');
    return status = const BlockStatus(isBlocked: true, canMessage: false);
  }

  @override
  Future<BlockStatus> unblock(String userId) async {
    calls.add('unblock $userId');
    return status = const BlockStatus(isBlocked: false, canMessage: true);
  }

  @override
  Future<List<BlockedAccount>> fetchBlocked() async => const [];
}

/// For screens that show a person but are not about blocking.
Override noBlocksOverride() =>
    blockRepositoryProvider.overrideWithValue(FakeBlockRepository());
