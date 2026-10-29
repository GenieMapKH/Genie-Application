import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/shared/widgets/lists/load_more_on_scroll.dart';

Widget _list({
  required int rows,
  required bool enabled,
  required VoidCallback onLoadMore,
}) {
  return MaterialApp(
    home: LoadMoreOnScroll(
      enabled: enabled,
      onLoadMore: onLoadMore,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: rows,
        itemBuilder: (_, i) => SizedBox(height: 100, child: Text('row $i')),
      ),
    ),
  );
}

void main() {
  testWidgets('a first page too short to scroll asks for more', (tester) async {
    var asked = 0;
    await tester.pumpWidget(
      _list(rows: 3, enabled: true, onLoadMore: () => asked++),
    );
    await tester.pump();

    expect(asked, greaterThan(0));
  });

  testWidgets('a long list asks only near its end', (tester) async {
    var asked = 0;
    await tester.pumpWidget(
      _list(rows: 100, enabled: true, onLoadMore: () => asked++),
    );
    await tester.pump();
    expect(asked, 0);

    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pump();
    expect(asked, 0);

    await tester.drag(find.byType(ListView), const Offset(0, -6000));
    await tester.pump();
    expect(asked, greaterThan(0));
  });

  testWidgets('asks for nothing while disabled', (tester) async {
    var asked = 0;
    await tester.pumpWidget(
      _list(rows: 3, enabled: false, onLoadMore: () => asked++),
    );
    await tester.pump();

    expect(asked, 0);
  });
}
