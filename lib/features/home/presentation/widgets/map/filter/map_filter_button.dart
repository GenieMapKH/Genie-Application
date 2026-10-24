import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/home/presentation/screens/map_filter_page.dart';
import 'package:genie/features/home/presentation/widgets/map/map_button_icon.dart';
import 'package:genie/features/property/presentation/view_models/map_property_filter.dart';
import 'package:genie/shared/widgets/buttons/tactile_button.dart';

/// Opens the filter page. A dot shows that it narrows the map by something
/// the pills can't show (price, size or features).
class MapFilterButton extends ConsumerWidget {
  const MapFilterButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final narrowed = ref.watch(
      mapPropertyFilterProvider.select((f) => f.hasPageOnlyFilters),
    );
    return TactileButton(
      onPressed: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const MapFilterPage())),
      child: Align(
        widthFactor: 0.8,
        child: Stack(
          children: [
            const MapButtonIcon(
              asset: 'assets/icons/filter.svg',
              width: 76,
              height: 68,
            ),
            if (narrowed)
              Positioned(
                // On the button's rim, top right.
                top: 14,
                right: 18,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: context.colors.highlight,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.colors.surface, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
