import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/core/config/app_config.dart';
import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/core/media/app_image_cache.dart';
import 'package:genie/features/chat/e2ee/crypto_service.dart';
import 'package:genie/features/chat/providers/chat_service_providers.dart';
import 'package:genie/features/settings/data/app_settings_storage.dart';
import 'package:genie/features/settings/providers/app_settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

import 'package:genie/app/app.dart';
import 'package:genie/app/missing_config_app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:genie/firebase_options.dart';
import 'package:genie/app/navigation/chat_profile_navigation.dart';
import 'package:genie/features/chat/providers/chat_profile_opener.dart';

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

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (defaultTargetPlatform == TargetPlatform.android) {
    await _configureAndroidGraphics();
  }

  final cryptoService = await CryptoService.init();
  // Read before the first frame, so the app opens in the saved theme and language.
  final settingsStorage = AppSettingsStorage(
    await SharedPreferences.getInstance(),
  );

  runApp(
    ProviderScope(
      overrides: [
        cryptoServiceProvider.overrideWithValue(cryptoService),
        appSettingsStorageProvider.overrideWithValue(settingsStorage),
        chatProfileOpenerProvider.overrideWith(profileFromChatOpener),
      ],
      child: const MyApp(),
    ),
  );
}
