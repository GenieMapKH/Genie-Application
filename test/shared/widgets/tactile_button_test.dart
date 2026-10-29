import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/shared/widgets/buttons/tactile_button.dart';

const _key = Key('content');

Future<void> _pump(
  WidgetTester tester, {
  VoidCallback? onPressed,
  bool disableAnimations = false,
}) {
  return tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: TactileButton(
            onPressed: onPressed,
            child: const SizedBox(key: _key, width: 100, height: 100),
          ),
        ),
      ),
    ),
  );
}

double _scale(WidgetTester tester) {
  final transforms = tester.widgetList<Transform>(
    find.ancestor(of: find.byKey(_key), matching: find.byType(Transform)),
  );
  return transforms.isEmpty
      ? 1
      : transforms.first.transform.storage[0];
}

void main() {
  testWidgets('sinks while held and springs back to rest when let go', (
    tester,
  ) async {
    var taps = 0;
    await _pump(tester, onPressed: () => taps++);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(_key)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(_scale(tester), closeTo(0.96, 0.005));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(_scale(tester), closeTo(1, 0.001));
    expect(taps, 1);
  });

  testWidgets('a disabled button does not move', (tester) async {
    await _pump(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(_key)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(_scale(tester), 1);
    await gesture.up();
  });

  testWidgets('with reduced motion it dims instead of shrinking', (
    tester,
  ) async {
    await _pump(tester, onPressed: () {}, disableAnimations: true);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(_key)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(Transform), findsNothing);
    final opacity = tester.widget<Opacity>(find.byType(Opacity));
    expect(opacity.opacity, lessThan(1));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('is announced as a button', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, onPressed: () {});

    expect(
      tester.getSemantics(find.byType(TactileButton)),
      matchesSemantics(
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        isFocusable: false,
      ),
    );
    semantics.dispose();
  });
}
