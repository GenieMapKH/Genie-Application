import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/auth/data/repositories/auth_repository.dart';
import 'package:genie/features/notifications/application/push_notifications_controller.dart';
import 'package:genie/features/notifications/application/push_registration.dart';
import 'package:genie/features/notifications/data/notification_repository.dart';
import 'package:genie/features/notifications/data/push_messaging.dart';
import 'package:genie/features/notifications/data/system_notifications.dart';
import 'package:genie/features/profile/presentation/view_models/user_providers.dart';
import 'package:genie/features/settings/providers/app_settings_providers.dart';

final pushMessagingProvider = Provider<PushMessaging>(
  (ref) => FirebasePushMessaging(),
);

final systemNotificationsProvider = Provider<SystemNotifications>(
  (ref) => LocalSystemNotifications(),
);

final notificationRepositoryProvider = Provider(
  (ref) => NotificationRepository(dio: ref.watch(apiClientProvider)),
);

final pushRegistrationProvider = Provider<PushRegistration>((ref) {
  final registration = PushRegistration(
    messaging: ref.watch(pushMessagingProvider),
    repository: ref.watch(notificationRepositoryProvider),
    platform: PushRegistration.currentPlatform,
  );
  ref.onDispose(registration.dispose);
  return registration;
});

/// Opens a tapped notification. The screens it leads to belong to other
/// features, so the app supplies this at start-up (see `lib/app/navigation`).
/// Null (in tests, or before it is wired) only opens the app.
final pushOpenerProvider = Provider<PushOpener?>((ref) => null);

/// Supplied by the app: hides a push that is pointless on the current
/// screen. Everything is shown by default.
final foregroundPushFilterProvider = Provider<ForegroundPushFilter>(
  (ref) =>
      (_) => true,
);

/// Supplied by the call feature: rings for a call push that arrives while
/// the app is open.
final callPushHandlerProvider = Provider<CallPushHandler?>((ref) => null);

/// The language notifications are written in: the app's own, as the server
/// knows only English and Khmer.
final pushLocaleProvider = Provider<String>((ref) {
  final chosen = ref.watch(localeProvider);
  final language =
      chosen?.languageCode ?? PlatformDispatcher.instance.locale.languageCode;
  return language == 'km' ? 'km' : 'en';
});

/// Keeps this device registered while someone is signed in, in their
/// language. Kept alive by the app shell; true once registered.
final pushRegistrationSyncProvider = FutureProvider<bool>((ref) async {
  final profile = ref.watch(userProfileProvider);
  final userId = profile.hasError ? null : profile.valueOrNull?.id;
  final locale = ref.watch(pushLocaleProvider);
  if (userId == null) return false;
  try {
    return await ref.read(pushRegistrationProvider).start(locale: locale);
  } catch (e, stackTrace) {
    AppLogger.error('Push notifications not set up', e, stackTrace);
    return false;
  }
});

/// Shows pushes that arrive while the app is open and opens tapped ones.
/// Started once by the app shell.
final pushNotificationsProvider = FutureProvider<void>((ref) async {
  final controller = PushNotificationsController(
    messaging: ref.watch(pushMessagingProvider),
    system: ref.watch(systemNotificationsProvider),
    open: (message) async {
      final opener = ref.read(pushOpenerProvider);
      if (opener != null) await opener(message);
    },
    shouldShow: (message) => ref.read(foregroundPushFilterProvider)(message),
    onCallPush: (message) => ref.read(callPushHandlerProvider)?.call(message),
  );
  ref.onDispose(controller.dispose);
  try {
    await controller.start();
  } catch (e, stackTrace) {
    AppLogger.error('Push notifications not started', e, stackTrace);
  }
});
