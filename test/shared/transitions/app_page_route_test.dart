import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/shared/transitions/app_page_route.dart';

void main() {
  testWidgets('AppPageRoute transitions forward fromRight and backward fromLeft',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    AppPageRoute(
                      page: Builder(
                        builder: (innerContext) => Scaffold(
                          body: Center(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(innerContext).pushReplacement(
                                  AppPageRoute(
                                    page: const Scaffold(
                                      body: Center(
                                        child: Text('Replaced Screen'),
                                      ),
                                    ),
                                    direction: SlideDirection.fromLeft,
                                  ),
                                );
                              },
                              child: const Text('Go Replace Left'),
                            ),
                          ),
                        ),
                      ),
                      direction: SlideDirection.fromRight,
                    ),
                  );
                },
                child: const Text('Go Forward Right'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Go Forward Right'), findsOneWidget);
    expect(find.text('Go Replace Left'), findsNothing);

    // Tap to transition forward from right
    await tester.tap(find.text('Go Forward Right'));
    await tester.pumpAndSettle();

    expect(find.text('Go Replace Left'), findsOneWidget);

    // Tap to replace from left
    await tester.tap(find.text('Go Replace Left'));
    await tester.pumpAndSettle();

    expect(find.text('Replaced Screen'), findsOneWidget);

    // Popping the replaced screen should return directly to root in a single pop
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pop();
    await tester.pumpAndSettle();

    expect(find.text('Go Forward Right'), findsOneWidget);
  });
}
