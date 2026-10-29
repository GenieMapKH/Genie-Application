import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';
import 'package:tilomnov/features/follow/presentation/view_models/follow_providers.dart';
import 'package:tilomnov/features/safety/data/block_repository.dart';
import 'package:tilomnov/features/safety/data/models/block_status.dart';
import 'package:tilomnov/features/safety/data/models/blocked_account.dart';

final blockRepositoryProvider = Provider<BlockRepository>((ref) {
  return BlockRepository(ref.watch(apiClientProvider));
});

/// Whether the signed-in user blocked one person, and whether the two can
/// message. Dropped on sign-in or sign-out.
class BlockStatusNotifier extends FamilyAsyncNotifier<BlockStatus, String> {
  bool _busy = false;

  @override
  Future<BlockStatus> build(String userId) {
    ref.watch(isSignedInProvider);
    return ref.watch(blockRepositoryProvider).fetchStatus(userId);
  }

  /// Asks again: the server refused a message, so the other person may have
  /// blocked the signed-in user meanwhile.
  void refresh() {
    if (!_busy) ref.invalidateSelf();
  }

  /// Blocks them, or unblocks them if blocked. True when it happened.
  Future<bool> setBlocked(bool blocked) async {
    if (_busy) return false;
    _busy = true;
    try {
      final repository = ref.read(blockRepositoryProvider);
      final after = blocked
          ? await repository.block(arg)
          : await repository.unblock(arg);
      state = AsyncData(after);
      // Blocking removed the follows both ways: counts and the feed change.
      ref.invalidate(followSummaryProvider(arg));
      ref.read(followChangesProvider.notifier).state++;
      ref.invalidate(blockedAccountsProvider);
      return true;
    } catch (e) {
      AppLogger.error('Changing a block failed', e);
      return false;
    } finally {
      _busy = false;
    }
  }
}

final blockStatusProvider =
    AsyncNotifierProvider.family<BlockStatusNotifier, BlockStatus, String>(
      BlockStatusNotifier.new,
    );

/// The accounts the signed-in user blocked, for the list to unblock from.
final blockedAccountsProvider =
    FutureProvider.autoDispose<List<BlockedAccount>>((ref) {
      ref.watch(isSignedInProvider);
      return ref.watch(blockRepositoryProvider).fetchBlocked();
    });
