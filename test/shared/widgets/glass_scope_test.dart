import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/core/theme/app_theme.dart';
import 'package:tilomnov/shared/widgets/glass/glass_icon_button.dart';
import 'package:tilomnov/shared/widgets/glass/glass_scope.dart';
import 'package:tilomnov/shared/widgets/glass/glass_surface.dart';
import 'package:tilomnov/shared/widgets/layout/app_header_bar.dart';

Future<void> _pump(WidgetTester tester, Widget child, {required bool glass}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      builder: (context, page) => GlassScope(enabled: glass, child: page!),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => Scaffold(body: SafeArea(child: child)),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('page header', () {
    testWidgets('its back button is glass while glass is on, and goes back', (
      tester,
    ) async {
      await _pump(tester, const AppHeaderBar(title: 'Saved'), glass: true);
      await _open(tester);

      expect(find.byType(GlassSurface), findsOneWidget);
      expect(find.byTooltip('Back'), findsOneWidget);

      await tester.tap(find.byType(GlassIconButton));
      await tester.pumpAndSettle();
      expect(find.text('Saved'), findsNothing);
    });

    testWidgets('keeps the plain arrow without glass', (tester) async {
      await _pump(tester, const AppHeaderBar(title: 'Saved'), glass: false);
      await _open(tester);

      expect(find.byType(GlassSurface), findsNothing);
      expect(find.byIcon(LucideIcons.arrowLeft), findsOneWidget);
    });
  });

  testWidgets('no scope above means no glass', (tester) async {
    await tester.pumpWidget(
      Builder(
        builder: (context) =>
            Text('${GlassScope.of(context)}', textDirection: TextDirection.ltr),
      ),
    );
    expect(find.text('false'), findsOneWidget);
  });

  testWidgets('a glass button without an action ignores taps', (tester) async {
    var taps = 0;
    await _pump(
      tester,
      Column(
        children: [
          const GlassIconButton(icon: LucideIcons.phone, onPressed: null),
          GlassIconButton(icon: Icons.share, onPressed: () => taps++),
        ],
      ),
      glass: true,
    );
    await _open(tester);

    await tester.tap(find.byIcon(LucideIcons.phone));
    await tester.tap(find.byIcon(Icons.share));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });
}
