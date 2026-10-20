import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/features/auth/presentation/widgets/sign_in_required_dialog.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/presentation/view_models/saved_property_ids_provider.dart';
import 'package:genie/features/property/presentation/widgets/saved_property_card.dart';

/// A publisher's listing cards, as many per row as fit: two on a phone,
/// more on a tablet.
class PublisherListingsGrid extends ConsumerWidget {
  final List<PropertyModel> properties;
  final double gutter;
  final ValueChanged<PropertyModel> onOpen;

  const PublisherListingsGrid({
    super.key,
    required this.properties,
    required this.gutter,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rebuilt when a heart is toggled, here or anywhere else.
    final savedIds = ref.watch(savedPropertyIdsProvider).valueOrNull ?? {};

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 0),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 240,
          mainAxisSpacing: 16,
          crossAxisSpacing: 12,
          childAspectRatio: 0.68,
        ),
        itemCount: properties.length,
        itemBuilder: (context, index) {
          final property = properties[index];
          return SavedPropertyCard(
            property: property,
            isFavorite: savedIds.contains(property.id),
            onTap: () => onOpen(property),
            onFavoriteToggled: () {
              if (requireSignIn(context, ref)) {
                ref.read(savedPropertyIdsProvider.notifier).toggle(property.id);
              }
            },
          );
        },
      ),
    );
  }
}
