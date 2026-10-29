import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/shared/widgets/media/tinted_svg.dart';

/// Every icon drawn in one colour, with the colour put in when it is read
/// rather than by a filter: no pixel may keep the icon's own colour, also
/// where the file relies on the default black fill or on `currentColor`.
void main() {
  const tint = Color(0xFFFF0000);
  final icons =
      Directory('assets/icons')
          .listSync()
          .whereType<File>()
          .map((file) => file.path.replaceAll(r'\', '/'))
          .where((path) => path.endsWith('.svg'))
          // Flags are pictures, never tinted.
          .where((path) => !path.contains('/flag_'))
          .toList()
        ..sort();

  for (final icon in icons) {
    testWidgets('$icon is drawn only in the tint', (tester) async {
      final svg = File(icon).readAsStringSync();
      final info = await tester.runAsync(
        () => vg.loadPicture(
          SvgStringLoader(
            svg,
            theme: const SvgTheme(currentColor: tint),
            colorMapper: TintedSvg.mapperFor(tint),
          ),
          null,
        ),
      );
      final image = await tester.runAsync(
        () => info!.picture.toImage(
          info.size.width.ceil(),
          info.size.height.ceil(),
        ),
      );
      final bytes = await tester.runAsync(
        () => image!.toByteData(format: ui.ImageByteFormat.rawStraightRgba),
      );

      var painted = 0;
      var offTint = 0;
      for (var i = 0; i < bytes!.lengthInBytes; i += 4) {
        final alpha = bytes.getUint8(i + 3);
        if (alpha < 128) continue;
        painted++;
        final red = bytes.getUint8(i);
        final green = bytes.getUint8(i + 1);
        final blue = bytes.getUint8(i + 2);
        if (red < 200 || green > 60 || blue > 60) offTint++;
      }
      expect(painted, greaterThan(0), reason: 'the icon draws nothing');
      expect(offTint, 0, reason: '$offTint of $painted pixels are not red');
    });
  }
}
