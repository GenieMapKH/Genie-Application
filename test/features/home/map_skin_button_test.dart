import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/core/theme/app_theme.dart';
import 'package:tilomnov/features/home/presentation/providers/map_state_provider.dart';
import 'package:tilomnov/features/home/presentation/widgets/map/map_skin_button.dart';
import 'package:tilomnov/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('previews each next skin and supports tap and keyboard', (
    tester,
  ) async {
    final skin = ValueNotifier(MapSkin.defaultMap);
    addTearDown(skin.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: ValueListenableBuilder(
              valueListenable: skin,
              builder: (context, current, _) => MapSkinButton(
                currentSkin: current,
                onPressed: () => skin.value = current.next,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Switch to Satellite map'), findsOneWidget);
    await tester.tap(find.byType(MapSkinButton));
    await tester.pumpAndSettle();
    expect(skin.value, MapSkin.satellite);
    expect(find.byTooltip('Switch to Default map'), findsOneWidget);
    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(MapSkinButton),
        matching: find.byType(Container),
      ),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(
      (decoration.image!.image as AssetImage).assetName,
      'assets/images/homescreen/mapDefault.png',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(skin.value, MapSkin.defaultMap);
    expect(find.byTooltip('Switch to Satellite map'), findsOneWidget);
    await tester.tap(find.byType(MapSkinButton));
    await tester.pumpAndSettle();
    expect(skin.value, MapSkin.satellite);
    expect(tester.takeException(), isNull);
  });
}
