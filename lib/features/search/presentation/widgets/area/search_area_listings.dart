import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/search/data/search_failure.dart';
import 'package:genie/features/search/presentation/view_models/search_area_controller.dart';
import 'package:genie/features/search/presentation/view_models/search_selection.dart';
import 'package:genie/features/search/presentation/widgets/property_result_tile.dart';
import 'package:genie/features/search/presentation/widgets/search_message_view.dart';
import 'package:genie/features/search/presentation/widgets/search_skeleton_list.dart';
import 'package:genie/l10n/l10n.dart';

/// The body of the results panel, as a sliver: placeholder rows while
/// loading, the reason and a retry when it failed, else the listings.
class SearchAreaListings extends StatelessWidget {
  final SearchAreaState state;
  final ValueChanged<PropertyModel> onOpenProperty;
  final VoidCallback onRetry;

  const SearchAreaListings({
    super.key,
    required this.state,
    required this.onOpenProperty,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return state.area.when(
      skipLoadingOnReload: true,
      loading: () => const SliverToBoxAdapter(child: SearchSkeletonList()),
      error: (error, _) => SliverToBoxAdapter(
        child: SearchMessageView.failure(
          context,
          error is SearchFailure ? error.reason : SearchFailureReason.unknown,
          onRetry: onRetry,
        ),
      ),
      data: (area) {
        if (area.properties.isEmpty) {
          return SliverToBoxAdapter(
            child: SearchMessageView(
              icon: Icons.holiday_village_outlined,
              title: switch (state.target) {
                PlaceTarget() => context.l10n.searchAreaEmpty,
                PersonTarget() => context.l10n.searchPersonEmpty,
              },
            ),
          );
        }
        return SliverList.builder(
          itemCount: area.properties.length,
          itemBuilder: (context, index) {
            final property = area.properties[index];
            return PropertyResultTile(
              property: property,
              onTap: () => onOpenProperty(property),
            );
          },
        );
      },
    );
  }
}
