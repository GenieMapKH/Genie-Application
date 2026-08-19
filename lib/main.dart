import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genie/features/auth/presentation/welcome_page.dart';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request the latest Android Map renderer which fixes lag and supports high refresh rates
  if (defaultTargetPlatform == TargetPlatform.android) {
    // try {
    //   await FlutterDisplayMode.setHighRefreshRate();
    // } catch (e) {
    //   // Ignore on devices where it's not supported
    // }

    AndroidMapRenderer mapRenderer = AndroidMapRenderer.latest;
    final GoogleMapsFlutterPlatform mapsImplementation = GoogleMapsFlutterPlatform.instance;
    if (mapsImplementation is GoogleMapsFlutterAndroid) {
      mapsImplementation.initializeWithRenderer(mapRenderer);
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Genie',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        canvasColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F5BD5),
          surface: Colors.white,
        ),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
        useMaterial3: true,
      ),
      home: const WelcomePage(),
    );
  }
}
