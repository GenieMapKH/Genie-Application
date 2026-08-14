import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/shared/transitions/app_page_route.dart';

void main() {
  testWidgets('AppPageRoute transitions smoothly between pages',
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
                      page: const Scaffold(
                        body: Center(
                          child: Text('Destination Screen'),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Go Forward'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Go Forward'), findsOneWidget);
    expect(find.text('Destination Screen'), findsNothing);

    // Tap to transition forward
    await tester.tap(find.text('Go Forward'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();

    expect(find.text('Destination Screen'), findsOneWidget);
  });
}
