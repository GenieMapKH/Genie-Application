import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';
import 'package:tilomnov/features/chat/providers/chat_service_providers.dart';
import 'package:tilomnov/features/home/presentation/providers/main_nav_provider.dart';
import 'package:tilomnov/features/notifications/providers/notification_providers.dart';
import 'package:tilomnov/features/profile/presentation/view_models/user_providers.dart';
import 'package:tilomnov/features/property/presentation/view_models/own_listings_providers.dart';
import 'package:tilomnov/features/property/presentation/view_models/own_map_properties_provider.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_providers.dart';

/// Signs this device out and forgets everything that was loaded for the user.
///
/// It lives in `app/` because it reaches into several features: no single
/// feature may know about all the others. Also used after the server ended
/// the session itself (all devices signed out, account deactivated or
/// deleted); telling the server again is then harmless.
final signOutProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    // First, while the session still lets this device tell the server: its
    // notifications must stop with the session.
    await ref.read(pushRegistrationProvider).stop();
    await ref.read(authServiceProvider).logout();

    // Back to the Explore tab, and drop everything cached for this user.
    ref.read(mainNavProvider.notifier).resetToHome();
    ref.invalidate(userProfileProvider);
    ref.invalidate(propertiesProvider);
    ref.invalidate(ownMapPropertiesProvider);
    ref.invalidate(publicPropertiesProvider);
    // Closes the chat connection now instead of when the profile reloads.
    ref.invalidate(chatSocketServiceProvider);
  };
});
