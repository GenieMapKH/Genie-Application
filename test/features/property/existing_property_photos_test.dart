import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/property/presentation/widgets/existing_property_photos.dart';

import '../../support/test_app.dart';

void main() {
  testWidgets('each saved photo can be taken off', (tester) async {
    final removed = <String>[];
    await pumpTestApp(
      tester,
      Scaffold(
        body: ExistingPropertyPhotos(
          urls: const ['https://cdn.test/a.jpg', 'https://cdn.test/b.jpg'],
          removedCount: 0,
          onRemove: removed.add,
          onRestore: () {},
        ),
      ),
    );

    expect(find.bySemanticsLabel('Remove photo'), findsNWidgets(2));
    await tester.tap(find.byIcon(Icons.close).last);

    expect(removed, ['https://cdn.test/b.jpg']);
    expect(find.textContaining('Undo remove'), findsNothing);
  });

  testWidgets('photos taken off can be brought back before saving', (
    tester,
  ) async {
    var restored = false;
    await pumpTestApp(
      tester,
      Scaffold(
        body: ExistingPropertyPhotos(
          urls: const [],
          removedCount: 2,
          onRemove: (_) {},
          onRestore: () => restored = true,
        ),
      ),
    );

    expect(find.text('Current photos (0)'), findsOneWidget);
    await tester.tap(find.text('Undo remove (2)'));

    expect(restored, isTrue);
  });
}
