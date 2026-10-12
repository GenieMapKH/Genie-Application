import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/core/config/app_config.dart';
import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/chat/e2ee/crypto_service.dart';
import 'package:genie/features/chat/providers/chat_service_providers.dart';
import 'package:genie/features/settings/data/app_settings_storage.dart';
import 'package:genie/features/settings/providers/app_settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

import 'package:genie/app/app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:genie/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const envFile = kReleaseMode ? '.env.production' : '.env';
  await dotenv.load(fileName: envFile);
  // Which server this build talks to: chat only works between devices on
  // the same one.
  AppLogger.debug('API server: ${AppConfig.apiBaseUrl}');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Request the latest Android Map renderer which fixes lag and supports high refresh rates
  if (defaultTargetPlatform == TargetPlatform.android) {
    AndroidMapRenderer mapRenderer = AndroidMapRenderer.latest;
    final GoogleMapsFlutterPlatform mapsImplementation =
        GoogleMapsFlutterPlatform.instance;
    if (mapsImplementation is GoogleMapsFlutterAndroid) {
      mapsImplementation.initializeWithRenderer(mapRenderer);
    }
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
      ],
      child: const MyApp(),
    ),
  );
}
