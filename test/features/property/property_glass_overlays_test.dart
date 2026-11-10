import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/property/presentation/view_models/own_listings_tab.dart';
import 'package:tilomnov/features/property/presentation/widgets/my_properties/property_tabs.dart';
import 'package:tilomnov/features/property/presentation/widgets/property_type_pill.dart';
import 'package:tilomnov/shared/widgets/glass/glass_scope.dart';
import 'package:tilomnov/shared/widgets/glass/glass_surface.dart';

import '../../support/test_app.dart';

Future<void> _pump(WidgetTester tester, Widget child, {required bool glass}) =>
    pumpTestApp(
      tester,
      GlassScope(
        enabled: glass,
        child: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  final picked = <OwnListingsTab>[];
  final tabs = PropertyTabs(
    countByStatus: const {'Active': 2, 'Pending': 1},
    selected: OwnListingsTab.active,
    onSelected: picked.add,
  );

  for (final glass in [true, false]) {
    final look = glass ? 'glass' : 'solid';

    testWidgets('the type pill names the type ($look)', (tester) async {
      await _pump(
        tester,
        const PropertyTypePill(propertyType: 'House', compact: true),
        glass: glass,
      );

      expect(find.text('House'), findsOneWidget);
      expect(find.byType(GlassSurface), glass ? findsOneWidget : findsNothing);
    });

    testWidgets('tapping a status tab picks it ($look)', (tester) async {
      picked.clear();
      await _pump(tester, tabs, glass: glass);

      await tester.tap(find.textContaining('Draft'));
      await tester.tap(find.textContaining('Active'));

      expect(picked, [OwnListingsTab.draft]);
    });

    testWidgets('the status tabs show every count ($look)', (tester) async {
      await _pump(tester, tabs, glass: glass);

      expect(find.textContaining('2'), findsOneWidget);
      expect(find.textContaining('1'), findsOneWidget);
      expect(find.textContaining('0'), findsNWidgets(2));
      // One capsule for all four, not one each.
      expect(find.byType(GlassSurface), glass ? findsOneWidget : findsNothing);
    });
  }
}
