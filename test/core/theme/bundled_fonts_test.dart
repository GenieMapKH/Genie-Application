import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// The app ships its fonts (assets/google_fonts), so text never waits for a
/// download, nor falls back to another font while offline.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every font weight the app uses is bundled', () async {
    final allowed = GoogleFonts.config.allowRuntimeFetching;
    GoogleFonts.config.allowRuntimeFetching = false;
    addTearDown(() => GoogleFonts.config.allowRuntimeFetching = allowed);

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

    // Throws when a font is neither bundled nor allowed to be fetched.
    await expectLater(GoogleFonts.pendingFonts(), completes);
  });
}
