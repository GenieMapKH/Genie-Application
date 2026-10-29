import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tilomnov/features/property/presentation/widgets/detail/property_detail_route.dart';

/// Stacks the black backdrops of every open sheet the way they show on screen.
double _backdropOpacity(WidgetTester tester) {
  var clear = 1.0;
  for (final box in tester.widgetList<ColoredBox>(find.byType(ColoredBox))) {
    if (box.color.r == 0 && box.color.g == 0 && box.color.b == 0) {
      clear *= 1 - box.color.a;
    }
  }
  return 1 - clear;
}

/// Width as drawn, after the route's scaling (`getSize` ignores transforms).
double _onScreenWidth(WidgetTester tester, Finder finder) =>
    tester.getBottomRight(finder).dx - tester.getTopLeft(finder).dx;

/// A stand-in sheet: a hero (as the real one is) that fills 90% of the screen.
class _Sheet extends StatelessWidget {
  final String label;
  final VoidCallback? onOpenNext;

  const _Sheet({required this.label, this.onOpenNext});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: PropertyDetailRoute.sheetHeightFactor,
          child: Hero(
            tag: 'sheet_$label',
            child: Material(
              color: Colors.white,
              child: SizedBox.expand(
                child: Center(
                  child: GestureDetector(onTap: onOpenNext, child: Text(label)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('replacing a sheet grows the next one out of the tapped tile '
      'and keeps the backdrop steady', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: Text('map')),
      ),
    );

    void openSecond() => navigatorKey.currentState!.pushReplacement(
      PropertyDetailRoute(
        origin: const Rect.fromLTWH(40, 40, 80, 100),
        page: const _Sheet(label: 'second'),
      ),
    );
    navigatorKey.currentState!.push(
      PropertyDetailRoute(
        page: _Sheet(label: 'first', onOpenNext: openSecond),
      ),
    );
    await tester.pumpAndSettle();
    expect(_backdropOpacity(tester), closeTo(0.25, 0.001));

    await tester.tap(find.text('first'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    // Mid-way the incoming sheet is still small, on its way out of the tile.
    final growing = _onScreenWidth(tester, find.text('second'));

    var darkest = 0.0;
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      darkest = darkest > _backdropOpacity(tester)
          ? darkest
          : _backdropOpacity(tester);
    }
    expect(darkest, lessThanOrEqualTo(0.2501));

    await tester.pumpAndSettle();
    expect(find.text('first'), findsNothing);
    expect(find.text('second'), findsOneWidget);
    expect(growing, lessThan(_onScreenWidth(tester, find.text('second'))));
    expect(_backdropOpacity(tester), closeTo(0.25, 0.001));
  });
}
