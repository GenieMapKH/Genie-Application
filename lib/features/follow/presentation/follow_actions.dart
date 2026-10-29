import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/features/auth/presentation/widgets/sign_in_required_dialog.dart';
import 'package:tilomnov/features/follow/data/follow_repository.dart';
import 'package:tilomnov/features/follow/presentation/view_models/follow_providers.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/utils/app_popup.dart';

/// Follows [userId], or unfollows them if already followed, from wherever a
/// follow button is: a guest is asked to sign in first, and a refusal is
/// explained.
Future<void> toggleFollow(
  BuildContext context,
  WidgetRef ref,
  String userId,
) async {
  if (!requireSignIn(context, ref)) return;
  final l10n = context.l10n;
  final provider = followSummaryProvider(userId);

  // Whether you follow them could not be read: ask again first, since
  // following needs to know.
  if (ref.read(provider) case AsyncError(hasValue: false)) {
    ref.invalidate(provider);
    try {
      await ref.read(provider.future);
    } catch (e) {
      AppLogger.error('Reading a follow failed', e);
      if (context.mounted) {
        AppPopup.showError(context, l10n.profileFollowFailed);
      }
      return;
    }
    if (!context.mounted) return;
  }

  final failure = await ref.read(provider.notifier).toggle();
  if (failure == null || !context.mounted) return;
  AppPopup.showError(context, switch (failure) {
    FollowFailure.limitReached => l10n.profileFollowLimit(
      FollowLimitReached.limit,
    ),
    FollowFailure.failed => l10n.profileFollowFailed,
  });
}
