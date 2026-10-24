import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/auth/data/repositories/auth_repository.dart';
import 'package:genie/features/follow/data/follow_repository.dart';
import 'package:genie/features/follow/data/models/follow_summary.dart';

final followRepositoryProvider = Provider<FollowRepository>((ref) {
  return FollowRepository(ref.watch(apiClientProvider));
});

/// Goes up by one each time the signed-in user follows or unfollows
/// someone: whatever shows followed people's listings (the feed) reloads.
final followChangesProvider = StateProvider<int>((ref) => 0);

/// Why a follow or unfollow did not happen.
enum FollowFailure { limitReached, failed }

/// The follow counts on one person's profile, and following them from it.
/// Kept after the profile closes, so opening it again shows the last known
/// state at once while [refresh] checks it; dropped on sign-in or sign-out.
class FollowSummaryNotifier extends FamilyAsyncNotifier<FollowSummary, String> {
  bool _busy = false;

  @override
  Future<FollowSummary> build(String userId) {
    ref.watch(isSignedInProvider);
    return ref.watch(followRepositoryProvider).fetchSummary(userId);
  }

  /// Fetches again, still showing the known state until the answer comes.
  /// Skipped while a follow or unfollow is on its way.
  void refresh() {
    if (!_busy) ref.invalidateSelf();
  }

  /// Follows them, or unfollows them if already followed. Shown at once;
  /// put back as it was when the server refuses, with the reason. Null
  /// when it happened (or nothing was asked: not loaded yet, or a tap
  /// already on its way).
  Future<FollowFailure?> toggle() async {
    final before = state.valueOrNull;
    if (before == null || _busy) return null;
    _busy = true;
    final following = !before.isFollowing;
    state = AsyncData(before.expecting(following: following));

    try {
      final repository = ref.read(followRepositoryProvider);
      final after = following
          ? await repository.follow(arg)
          : await repository.unfollow(arg);
      state = AsyncData(after);
      ref.read(followChangesProvider.notifier).state++;
      return null;
    } on FollowLimitReached {
      state = AsyncData(before);
      return FollowFailure.limitReached;
    } catch (e) {
      AppLogger.error('Changing a follow failed', e);
      state = AsyncData(before);
      return FollowFailure.failed;
    } finally {
      _busy = false;
    }
  }
}

final followSummaryProvider =
    AsyncNotifierProvider.family<FollowSummaryNotifier, FollowSummary, String>(
      FollowSummaryNotifier.new,
    );
