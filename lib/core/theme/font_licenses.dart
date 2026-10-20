import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Lists the bundled fonts' licenses (SIL Open Font License) with the app's
/// other licenses. Read only when a licenses page asks for them.
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final (font, file) in const [
      ('Inter', 'Inter-OFL.txt'),
      ('Roboto Mono', 'RobotoMono-OFL.txt'),
    ]) {
      yield LicenseEntryWithLineBreaks([
        font,
      ], await rootBundle.loadString('assets/google_fonts/$file'));
    }
  });
}
