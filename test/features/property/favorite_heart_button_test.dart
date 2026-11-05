import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/core/theme/app_theme.dart';
import 'package:tilomnov/features/property/presentation/widgets/favorite_heart_button.dart';
import 'package:tilomnov/shared/widgets/glass/glass_scope.dart';
import 'package:tilomnov/shared/widgets/glass/glass_surface.dart';

void main() {
  late List<Object?> haptics;

  setUp(() {
    haptics = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments);
          }
          return null;
        });
  });

  Future<List<String>> pump(
    WidgetTester tester, {
    required bool saved,
    bool glass = false,
  }) async {
    final taps = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: GlassScope(
          enabled: glass,
          child: Center(
            child: FavoriteHeartButton(
              isFavorite: saved,
              onPressed: () => taps.add('tap'),
            ),
          ),
        ),
      ),
    );
    return taps;
  }

  testWidgets('saving answers once, with a light tap in the hand', (
    tester,
  ) async {
    final taps = await pump(tester, saved: false);

    await tester.tap(find.byType(FavoriteHeartButton));
    await tester.pumpAndSettle();

    expect(taps, ['tap']);
    expect(haptics, ['HapticFeedbackType.lightImpact']);
  });

  testWidgets('unsaving answers once, without a haptic', (tester) async {
    final taps = await pump(tester, saved: true);

    await tester.tap(find.byType(FavoriteHeartButton));
    await tester.pumpAndSettle();

    expect(taps, ['tap']);
    expect(haptics, isEmpty);
  });

  testWidgets('the heart settles back to its size', (tester) async {
    await pump(tester, saved: false);
    await tester.tap(find.byType(FavoriteHeartButton));
    await pump(tester, saved: true);
    await tester.pumpAndSettle();

    final scale = tester.widget<ScaleTransition>(
      find
          .descendant(
            of: find.byType(FavoriteHeartButton),
            matching: find.byType(ScaleTransition),
          )
          .first,
    );
    expect(scale.scale.value, closeTo(1, 0.001));
  });

  testWidgets('with glass, the glass stays still and only the heart springs', (
    tester,
  ) async {
    final taps = await pump(tester, saved: false, glass: true);

    expect(find.byType(GlassSurface), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byType(GlassSurface),
        matching: find.byType(ScaleTransition),
      ),
      findsNothing,
    );

    await tester.tap(find.byType(FavoriteHeartButton));
    await tester.pumpAndSettle();
    expect(taps, ['tap']);
  });
}
