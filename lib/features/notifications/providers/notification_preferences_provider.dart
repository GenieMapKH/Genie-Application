import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/notifications/data/notification_repository.dart';
import 'package:genie/features/notifications/models/notification_preferences.dart';
import 'package:genie/features/notifications/providers/notification_providers.dart';

/// The user's notification switches, as the server holds them.
class NotificationPreferencesNotifier
    extends StateNotifier<AsyncValue<NotificationPreferences>> {
  final NotificationRepository repository;

  /// True while a change is being saved; the switches wait for it.
  bool saving = false;

  NotificationPreferencesNotifier({required this.repository})
    : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final preferences = await repository.fetchPreferences();
      if (mounted) state = AsyncValue.data(preferences);
    } catch (e, stackTrace) {
      AppLogger.error('Notification settings not loaded', e, stackTrace);
      if (mounted) state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Flips the switch at once and saves it. False (and the switch back as
  /// it was) when it could not be saved.
  Future<bool> change({
    bool? chatMessages,
    bool? promotions,
    bool? savedSearchAlerts,
    bool? followedListings,
    bool? savedListingUpdates,
  }) async {
    final previous = state.valueOrNull;
    if (previous == null || saving) return false;

    saving = true;
    state = AsyncValue.data(
      previous.copyWith(
        chatMessages: chatMessages,
        promotions: promotions,
        savedSearchAlerts: savedSearchAlerts,
        followedListings: followedListings,
        savedListingUpdates: savedListingUpdates,
      ),
    );
    try {
      final saved = await repository.updatePreferences(
        chatMessages: chatMessages,
        promotions: promotions,
        savedSearchAlerts: savedSearchAlerts,
        followedListings: followedListings,
        savedListingUpdates: savedListingUpdates,
      );
      if (mounted) state = AsyncValue.data(saved);
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Notification setting not saved', e, stackTrace);
      if (mounted) state = AsyncValue.data(previous);
      return false;
    } finally {
      saving = false;
    }
  }
}

final notificationPreferencesProvider =
    StateNotifierProvider.autoDispose<
      NotificationPreferencesNotifier,
      AsyncValue<NotificationPreferences>
    >(
      (ref) => NotificationPreferencesNotifier(
        repository: ref.watch(notificationRepositoryProvider),
      ),
    );

/// Whether the phone lets this app show notifications at all. Asked again
/// each time the settings page opens.
final notificationsAllowedProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(pushMessagingProvider).isAllowed(),
);
