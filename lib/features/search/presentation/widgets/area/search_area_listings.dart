import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/features/auth/presentation/widgets/sign_in_required_dialog.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/presentation/view_models/saved_property_ids_provider.dart';
import 'package:tilomnov/features/property/presentation/widgets/saved_property_card.dart';
import 'package:tilomnov/features/search/data/search_failure.dart';
import 'package:tilomnov/features/search/presentation/search_layout.dart';
import 'package:tilomnov/features/search/presentation/view_models/search_area_controller.dart';
import 'package:tilomnov/features/search/presentation/view_models/search_selection.dart';
import 'package:tilomnov/features/search/presentation/widgets/area/focused_listing_card.dart';
import 'package:tilomnov/features/search/presentation/widgets/search_message_view.dart';
import 'package:tilomnov/features/search/presentation/widgets/search_skeleton_list.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// The body of the results panel, as a sliver: placeholder rows while
/// loading, the reason and a retry when it failed, else the listings as
/// cards, in as many columns as the panel's width fits (like the map's
/// pull-up list of listings near the user).
class SearchAreaListings extends ConsumerWidget {
  final SearchAreaState state;

  /// The panel's height when pulled all the way up.
  final double height;

  /// A card was tapped.
  final ValueChanged<PropertyModel> onTapProperty;

  /// The focused card's "View property" button was tapped.
  final ValueChanged<PropertyModel> onOpenProperty;
  final VoidCallback onRetry;

  const SearchAreaListings({
    super.key,
    required this.state,
    required this.height,
    required this.onTapProperty,
    required this.onOpenProperty,
    required this.onRetry,
  });

  /// Its own, so a card of the same listing on another page (Saved, the
  /// pull-up list) does not fly into this one.
  static String heroTagOf(String propertyId) => 'search_area_hero_$propertyId';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              icon: LucideIcons.house,
              title: switch (state.target) {
                PlaceTarget() => context.l10n.searchAreaEmpty,
                PersonTarget() => context.l10n.searchPersonEmpty,
              },
            ),
          );
        }
        return SliverLayoutBuilder(
          builder: (context, constraints) =>
              _grid(context, ref, area.properties, constraints.crossAxisExtent),
        );
      },
    );
  }

  Widget _grid(
    BuildContext context,
    WidgetRef ref,
    List<PropertyModel> properties,
    double width,
  ) {
    final gutter = SearchLayout.gutter(width);
    final cardHeight = SearchLayout.cardHeight(
      SearchLayout.cardColumnWidth(width),
      sheetHeight: height,
    );
    final saved = ref.watch(savedPropertyIdsProvider).valueOrNull ?? const {};

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 0),
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: SearchLayout.cardColumns(width),
          mainAxisExtent: cardHeight,
          mainAxisSpacing: SearchLayout.cardSpacing + 4,
          crossAxisSpacing: SearchLayout.cardSpacing,
        ),
        itemCount: properties.length,
        itemBuilder: (context, index) {
          final property = properties[index];
          final card = SavedPropertyCard(
            property: property,
            isFavorite: saved.contains(property.id),
            heroTag: heroTagOf(property.id),
            onTap: () => onTapProperty(property),
            onFavoriteToggled: () {
              if (!requireSignIn(context, ref)) return;
              ref.read(savedPropertyIdsProvider.notifier).toggle(property.id);
            },
          );
          if (state.focused?.id != property.id) return card;
          return FocusedListingCard(
            onView: () => onOpenProperty(property),
            child: card,
          );
        },
      ),
    );
  }
}
