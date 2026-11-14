import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/home/presentation/widgets/map/map_capsule.dart';
import 'package:tilomnov/features/home/presentation/widgets/map/property_type_filters.dart';
import 'package:tilomnov/features/property/presentation/view_models/map_property_filter.dart';
import 'package:tilomnov/shared/widgets/buttons/tactile_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../support/test_app.dart';

void main() {
  testWidgets(
    'smaller pills preserve full touch targets and filter selection',
    (tester) async {
      await pumpTestApp(tester, const Scaffold(body: PropertyTypeFilters()));
      final pills = find.byType(MapCapsule);
      expect(tester.getSize(pills.first).height, lessThan(40));
      final buttons = find.byType(TactileButton);
      expect(tester.getSize(buttons.first).height, greaterThanOrEqualTo(48));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(PropertyTypeFilters)),
      );
      await tester.tap(find.text('House'));
      await tester.pumpAndSettle();
      expect(container.read(mapPropertyFilterProvider).propertyType, 'House');
      await tester.tap(find.text('Listing Type'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rent'));
      await tester.pumpAndSettle();
      expect(container.read(mapPropertyFilterProvider).listingTypes, ['Rent']);
      expect(tester.takeException(), isNull);
    },
  );
}
