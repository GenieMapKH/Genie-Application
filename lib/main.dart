import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

import 'package:genie/app/app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:genie/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const envFile = kReleaseMode ? ".env.production" : ".env";
  await dotenv.load(fileName: envFile);

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

  runApp(const ProviderScope(child: MyApp()));
}
