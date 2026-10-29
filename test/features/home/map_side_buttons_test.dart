import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilomnov/core/device/glass_capability.dart';
import 'package:tilomnov/features/home/presentation/widgets/glass/glass_surface.dart';
import 'package:tilomnov/core/theme/app_theme.dart';
import 'package:tilomnov/features/home/presentation/widgets/map/map_button_icon.dart';
import 'package:tilomnov/features/home/presentation/widgets/map/map_side_buttons.dart';
import 'package:tilomnov/features/settings/data/app_settings_storage.dart';
import 'package:tilomnov/features/settings/providers/app_settings_providers.dart';
import 'package:tilomnov/l10n/generated/app_localizations.dart';

Future<List<String>> _pump(WidgetTester tester, {bool glass = false}) async {
  final pressed = <String>[];
  SharedPreferences.setMockInitialValues({});
  final settings = AppSettingsStorage(await SharedPreferences.getInstance());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appSettingsStorageProvider.overrideWithValue(settings),
        glassCapableDeviceProvider.overrideWithValue(glass),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Stack(
            children: [
              MapSideButtons(
                bottom: 110,
                buttonSize: 76,
                onDrawPressed: () => pressed.add('draw'),
                onCoordinatesScanned: (_) => pressed.add('coordinates'),
                onGoToCurrentPosition: () => pressed.add('position'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return pressed;
}

Finder _disc(String tooltip) => find.descendant(
  of: find.byTooltip(tooltip),
  matching: find.byWidgetPredicate(
    (w) => w is DecoratedBox || w is GlassSurface,
  ),
).first;

void main() {
  testWidgets('draw and current position each take one tap', (tester) async {
    final pressed = await _pump(tester);

    await tester.tap(find.byTooltip('Draw'));
    await tester.tap(find.byType(MapButtonIcon));
    await tester.pumpAndSettle();

    expect(pressed, ['draw', 'position']);
  });

  testWidgets('coordinates opens the coordinate entry sheet', (tester) async {
    await _pump(tester);

    await tester.tap(find.byTooltip('Coordinates'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('the buttons stack on the right, as big as current position', (
    tester,
  ) async {
    await _pump(tester);
    final screen = tester.getRect(find.byType(Scaffold));
    final position = tester.getRect(find.byType(MapButtonIcon));
    // The artwork's disc: 44 px, 16 px in and 12 px down in its 76 px box.
    final positionDisc = Rect.fromLTWH(
      position.left + 16,
      position.top + 12,
      44,
      44,
    );

    final coordinates = tester.getRect(_disc('Coordinates'));
    final draw = tester.getRect(_disc('Draw'));
    expect(position.right, screen.right);
    for (final disc in [coordinates, draw]) {
      expect(disc.size, positionDisc.size);
      expect(disc.center.dx, positionDisc.center.dx);
    }
    expect(coordinates.bottom, lessThan(draw.top));
    expect(draw.bottom, lessThan(positionDisc.top));
  });

  testWidgets('on a glass phone every disc is glass, in the same place', (
    tester,
  ) async {
    await _pump(tester);
    final regular = [
      tester.getRect(_disc('Coordinates')),
      tester.getRect(_disc('Draw')),
    ];

    await _pump(tester, glass: true);

    // Coordinates, draw and current position.
    expect(find.byType(GlassSurface), findsNWidgets(3));
    expect(tester.getRect(_disc('Coordinates')), regular[0]);
    expect(tester.getRect(_disc('Draw')), regular[1]);
  });
}
