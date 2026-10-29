import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Runs before every test file. The app's fonts are bundled
/// (assets/google_fonts), so they are loaded here once: a font that finished
/// loading halfway through a test's frame would make text change size
/// between layout and paint. Tests never download fonts.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  for (final weight in const [
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
    FontWeight.w800,
  ]) {
    GoogleFonts.inter(fontWeight: weight);
  }
  GoogleFonts.robotoMono();
  await GoogleFonts.pendingFonts();
  await testMain();
}
