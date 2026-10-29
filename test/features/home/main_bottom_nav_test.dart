import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/core/device/glass_capability.dart';
import 'package:tilomnov/core/device/reduce_transparency.dart';
import 'package:tilomnov/features/chat/providers/chat_provider.dart';
import 'package:tilomnov/features/home/presentation/providers/main_nav_provider.dart';
import 'package:tilomnov/features/home/presentation/widgets/layout/classic_bottom_nav.dart';
import 'package:tilomnov/features/home/presentation/widgets/layout/glass_bottom_nav.dart';
import 'package:tilomnov/features/home/presentation/widgets/layout/main_bottom_nav.dart';

import '../../support/test_app.dart';

Future<void> _pump(
  WidgetTester tester, {
  required bool glassPhone,
  bool reduceTransparency = false,
  bool highContrast = false,
  Map<String, Object> savedSettings = const {},
}) {
  return pumpTestApp(
    tester,
    Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(highContrast: highContrast),
        child: const Scaffold(
          extendBody: true,
          body: SizedBox.expand(),
          bottomNavigationBar: MainBottomNav(),
        ),
      ),
    ),
    savedSettings: savedSettings,
    overrides: [
      signedInOverride(),
      unreadCountProvider.overrideWithValue(0),
      glassCapableDeviceProvider.overrideWithValue(glassPhone),
      reduceTransparencyProvider.overrideWith(
        (ref) => ReduceTransparencyNotifier(
          const ReduceTransparency(),
          initial: reduceTransparency,
        ),
      ),
    ],
  );
}

int _currentTab(WidgetTester tester) => ProviderScope.containerOf(
  tester.element(find.byType(MainBottomNav)),
).read(mainNavProvider).currentIndex;

void main() {
  testWidgets('a phone without glass keeps the regular bar', (tester) async {
    await _pump(tester, glassPhone: false);

    expect(find.byType(ClassicBottomNav), findsOneWidget);
    expect(find.byType(GlassBottomNav), findsNothing);
  });

  testWidgets('a glass phone gets the glass capsule in the same slot', (
    tester,
  ) async {
    await _pump(tester, glassPhone: true);

    expect(find.byType(GlassBottomNav), findsOneWidget);
    expect(
      tester.getSize(find.byType(GlassBottomNav)).height,
      GlassBottomNav.slotHeight,
    );
  });

  testWidgets('picking a tab moves the selection and settles', (tester) async {
    await _pump(tester, glassPhone: true);

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();

    expect(_currentTab(tester), MainTab.chat);
  });

  testWidgets('the regular bar returns when the user turns glass off', (
    tester,
  ) async {
    await _pump(
      tester,
      glassPhone: true,
      savedSettings: {'settings.glass_navigation': false},
    );

    expect(find.byType(ClassicBottomNav), findsOneWidget);
  });

  testWidgets('the regular bar returns with Reduce Transparency', (
    tester,
  ) async {
    await _pump(tester, glassPhone: true, reduceTransparency: true);

    expect(find.byType(ClassicBottomNav), findsOneWidget);
  });

  testWidgets('the regular bar returns with increased contrast', (
    tester,
  ) async {
    await _pump(tester, glassPhone: true, highContrast: true);

    expect(find.byType(ClassicBottomNav), findsOneWidget);
  });
}
