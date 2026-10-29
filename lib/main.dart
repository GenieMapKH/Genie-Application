import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/core/config/app_config.dart';
import 'package:tilomnov/core/device/glass_capability.dart';
import 'package:tilomnov/core/device/reduce_transparency.dart';
import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/core/media/app_image_cache.dart';
import 'package:tilomnov/core/theme/font_licenses.dart';
import 'package:tilomnov/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tilomnov/features/chat/e2ee/keys/crypto_service.dart';
import 'package:tilomnov/features/chat/providers/chat_service_providers.dart';
import 'package:tilomnov/features/settings/data/app_settings_storage.dart';
import 'package:tilomnov/features/settings/providers/app_settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

import 'package:tilomnov/app/app.dart';
import 'package:tilomnov/app/missing_config_app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tilomnov/firebase_options.dart';
import 'package:tilomnov/app/navigation/property_publisher_navigation.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_publisher_opener.dart';
import 'package:tilomnov/app/navigation/chat_listing_navigation.dart';
import 'package:tilomnov/app/navigation/chat_profile_navigation.dart';
import 'package:tilomnov/app/navigation/call_navigation.dart';
import 'package:tilomnov/app/navigation/push_navigation.dart';
import 'package:tilomnov/app/push_background_handler.dart';
import 'package:tilomnov/app/push_chat_text.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:tilomnov/features/chat/providers/chat_call_starter.dart';
import 'package:tilomnov/features/chat/providers/chat_profile_opener.dart';
import 'package:tilomnov/features/notifications/providers/notification_providers.dart';
import 'package:tilomnov/features/chat/providers/chat_listing_opener.dart';
import 'package:tilomnov/core/observability/error_reporting.dart';

/// Android only: asks for the newest Google Maps renderer and for the
/// display's highest refresh rate. Without the latter many devices keep a
/// Flutter app at 60Hz even on a 120Hz panel. Failures are logged and the app
/// carries on with the platform defaults.
Future<void> _configureAndroidGraphics() async {
  try {
    final GoogleMapsFlutterPlatform maps = GoogleMapsFlutterPlatform.instance;
    if (maps is GoogleMapsFlutterAndroid) {
      // Must finish before the first GoogleMap is created.
      await maps.initializeWithRenderer(AndroidMapRenderer.latest);
    }
  } catch (e, st) {
    AppLogger.error('Map renderer initialisation failed', e, st);
  }

  try {
    await FlutterDisplayMode.setHighRefreshRate();
  } catch (e, st) {
    AppLogger.error('Could not request the high refresh rate', e, st);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppImageCache.configureMemory();
  // A debug run must say which server it talks to. Without an env file the
  // app would quietly use the production server, so it says how to start
  // it properly instead (throwing here would only leave a blank screen).
  if (kDebugMode && !AppConfig.hasApiBaseUrl) {
    runApp(const MissingConfigApp());
    return;
  }
  // Which server this build talks to: chat only works between devices on
  // the same one.
  AppLogger.debug('API server: ${AppConfig.apiBaseUrl}');

  registerFontLicenses();

  // Independent of each other, so they run at the same time: the first
  // frame waits for the slowest, not for all of them in turn.
  final (
    _,
    _,
    cryptoService,
    _,
    preferences,
    glassCapable,
    reduceTransparency,
  ) = await (
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).then((_) {
      // A browser handles background pushes in web/firebase-messaging-sw.js.
      if (!kIsWeb) FirebaseMessaging.onBackgroundMessage(handleBackgroundPush);
    }),
    defaultTargetPlatform == TargetPlatform.android
        ? _configureAndroidGraphics()
        : Future<void>.value(),
    CryptoService.init(),
    // Read before the first frame, so no screen starts out treating a
    // signed-in user as a guest, or a guest as signed in.
    AuthStorage.load(),
    // Read before the first frame, so the app opens in the saved theme and
    // language.
    SharedPreferences.getInstance(),
    // Read before the first frame, so the navigation never starts in one
    // look and swaps to the other.
    GlassCapability().read(),
    const ReduceTransparency().read(),
  ).wait;
  final settingsStorage = AppSettingsStorage(preferences);

  // Crashes and uncaught errors are reported from here on, when configured.
  await ErrorReporting.run(
    () => runApp(
      ProviderScope(
        overrides: [
          cryptoServiceProvider.overrideWithValue(cryptoService),
          appSettingsStorageProvider.overrideWithValue(settingsStorage),
          glassCapableDeviceProvider.overrideWithValue(glassCapable),
          reduceTransparencyProvider.overrideWith(
            (ref) => ReduceTransparencyNotifier(
              const ReduceTransparency(),
              initial: reduceTransparency,
            ),
          ),
          chatProfileOpenerProvider.overrideWith(profileFromChatOpener),
          chatListingOpenerProvider.overrideWith(listingFromChatOpener),
          propertyPublisherOpenerProvider.overrideWith(
            publisherFromListingOpener,
          ),
          pushOpenerProvider.overrideWith(pushOpener),
          foregroundPushFilterProvider.overrideWith(foregroundPushFilter),
          chatCallStarterProvider.overrideWith(callFromChat),
          callPushHandlerProvider.overrideWith(callPushHandler),
          chatPushTextProvider.overrideWith(chatPushText),
        ],
        child: const MyApp(),
      ),
    ),
  );
}
