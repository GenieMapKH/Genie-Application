import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/auth/presentation/widgets/sign_in_required_dialog.dart';
import 'package:tilomnov/features/closest_listings/data/closest_listing.dart';
import 'package:tilomnov/features/closest_listings/presentation/closest_sheet_layout.dart';
import 'package:tilomnov/features/closest_listings/presentation/view_models/closest_listings_provider.dart';
import 'package:tilomnov/features/closest_listings/presentation/widgets/closest_listing_tile.dart';
import 'package:tilomnov/features/feed/presentation/widgets/feed_message_view.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/presentation/view_models/saved_property_ids_provider.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/feedback/load_failure_view.dart';
import 'package:tilomnov/shared/utils/paged_list.dart';
import 'package:tilomnov/shared/widgets/lists/loading_more_indicator.dart';

/// The slivers under the sheet's header: the listings in as many columns as
/// the sheet's [width] fits, or what to say while there are none.
class ClosestListingsBody extends ConsumerWidget {
  final double width;

  /// The sheet's height when pulled all the way up.
  final double height;
  final void Function(PropertyModel property) onOpen;

  const ClosestListingsBody({
    super.key,
    required this.width,
    required this.height,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(closestListingsProvider);
    final l10n = context.l10n;
    void retry() => ref.read(closestListingsProvider.notifier).refresh();

    return listings.when(
      // Kept while a new filter's list is on its way.
      skipLoadingOnReload: true,
      loading: () => SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: CircularProgressIndicator(color: context.colors.accent),
          ),
        ),
      ),
      error: (error, _) => _message(
        LoadFailureView(
          error: error,
          message: l10n.closestLoadFailed,
          onRetry: retry,
        ),
      ),
      data: (state) => state.listings.items.isEmpty
          ? _message(
              FeedMessageView(
                icon: Icons.travel_explore_rounded,
                title: l10n.closestEmptyTitle,
                hint: l10n.closestEmptyHint,
                actionLabel: l10n.commonRetry,
                onAction: retry,
              ),
            )
          : _grid(context, ref, state.listings),
    );
  }

  Widget _message(Widget message) => SliverToBoxAdapter(
    child: Padding(padding: const EdgeInsets.all(16), child: message),
  );

  Widget _grid(
    BuildContext context,
    WidgetRef ref,
    PagedList<ClosestListing> listings,
  ) {
    final gutter = ClosestSheetLayout.gutter(width);
    final tileHeight =
        ClosestSheetLayout.cardHeight(
          ClosestSheetLayout.columnWidth(width),
          sheetHeight: height,
        ) +
        ClosestListingTile.distanceLineHeight(MediaQuery.textScalerOf(context));
    final saved = ref.watch(savedPropertyIdsProvider).valueOrNull ?? const {};

    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(gutter, 4, gutter, 0),
          sliver: SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ClosestSheetLayout.columns(width),
              mainAxisExtent: tileHeight,
              mainAxisSpacing: ClosestSheetLayout.spacing + 4,
              crossAxisSpacing: ClosestSheetLayout.spacing,
            ),
            itemCount: listings.items.length,
            itemBuilder: (context, index) {
              final listing = listings.items[index];
              final id = listing.property.id;
              return ClosestListingTile(
                listing: listing,
                isFavorite: saved.contains(id),
                onOpen: () => onOpen(listing.property),
                onFavoriteToggled: () {
                  if (!requireSignIn(context, ref)) return;
                  ref.read(savedPropertyIdsProvider.notifier).toggle(id);
                },
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: listings.loadingMore
              ? const LoadingMoreIndicator()
              : const SizedBox(height: 24),
        ),
      ],
    );
  }
}
