import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/home/presentation/widgets/kept_tab_pages.dart';

/// Counts how often it was built from scratch, and keeps a counter as state.
class _CountingPage extends StatefulWidget {
  static final created = <int, int>{};

  final int index;

  const _CountingPage(this.index);

  @override
  State<_CountingPage> createState() => _CountingPageState();
}

class _CountingPageState extends State<_CountingPage> {
  int taps = 0;

  @override
  void initState() {
    super.initState();
    _CountingPage.created.update(widget.index, (n) => n + 1, ifAbsent: () => 1);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: TextButton(
        onPressed: () => setState(() => taps++),
        child: Text('page ${widget.index}: $taps'),
      ),
    );
  }
}

void main() {
  setUp(_CountingPage.created.clear);

  Future<void> show(WidgetTester tester, int current, int previous) async {
    await tester.pumpWidget(
      MaterialApp(
        home: KeptTabPages(
          current: current,
          previous: previous,
          hasPage: (index) => index != 0,
          pageBuilder: (_, index) => _CountingPage(index),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a tab is built once and comes back as it was left', (
    tester,
  ) async {
    await show(tester, 1, 0);
    await tester.tap(find.text('page 1: 0'));
    await tester.pump();

    await show(tester, 2, 1);
    await show(tester, 0, 2);
    await show(tester, 1, 0);

    expect(find.text('page 1: 1'), findsOneWidget);
    expect(_CountingPage.created, {1: 1, 2: 1});
  });

  testWidgets('only the tab shown is on screen', (tester) async {
    await show(tester, 1, 0);
    await show(tester, 2, 1);

    expect(find.text('page 2: 0'), findsOneWidget);
    // Kept, but hidden: not found among what is shown.
    expect(find.text('page 1: 0'), findsNothing);
    expect(find.text('page 1: 0', skipOffstage: false), findsOneWidget);
  });

  testWidgets('a hidden tab does not animate', (tester) async {
    await show(tester, 1, 0);
    final page1 = tester.element(find.text('page 1: 0'));
    await show(tester, 0, 1);

    expect(TickerMode.valuesOf(page1).enabled, isFalse);
  });

  testWidgets('home has no page and nothing is built for it', (tester) async {
    await show(tester, 0, 0);

    expect(_CountingPage.created, isEmpty);
  });
}
