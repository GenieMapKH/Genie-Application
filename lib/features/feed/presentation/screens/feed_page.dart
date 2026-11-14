import 'package:tilomnov/features/advertisements/data/advertisement.dart';
import 'package:tilomnov/features/advertisements/presentation/advertisements_provider.dart';
import 'package:tilomnov/features/advertisements/presentation/advertisement_banner.dart';
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/feed/presentation/view_models/feed_provider.dart';
import 'package:tilomnov/features/feed/presentation/widgets/feed_header.dart';
import 'package:tilomnov/features/feed/presentation/widgets/feed_filter_sheet.dart';
import 'package:tilomnov/features/feed/data/feed_filters.dart';
import 'package:tilomnov/features/feed/presentation/widgets/feed_listing_card.dart';
import 'package:tilomnov/features/feed/presentation/widgets/feed_message_view.dart';
import 'package:tilomnov/features/home/presentation/providers/main_nav_provider.dart';
import 'package:tilomnov/features/home/presentation/providers/show_property_on_map.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/presentation/view_models/saved_property_ids_provider.dart';
import 'package:tilomnov/features/property/presentation/widgets/detail/property_detail_sheet.dart';
import 'package:tilomnov/features/search/data/models/publisher_summary.dart';
import 'package:tilomnov/features/search/presentation/screens/publisher_profile_page.dart';
import 'package:tilomnov/features/search/presentation/view_models/search_area_controller.dart';
import 'package:tilomnov/features/search/presentation/view_models/search_selection.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/utils/paged_list.dart';
import 'package:tilomnov/shared/widgets/feedback/page_load_failure.dart';
import 'package:tilomnov/shared/widgets/feedback/refresh_outcome.dart';
import 'package:tilomnov/shared/widgets/layout/paused_while_hidden.dart';
import 'package:tilomnov/shared/widgets/lists/load_more_on_scroll.dart';
import 'package:tilomnov/shared/widgets/lists/loading_more_indicator.dart';

/// The Feed tab: new listings of the people the user follows, newest first.
class FeedPage extends ConsumerWidget {
  final bool isEmbedded;
  final VoidCallback? onBackPressed;

  const FeedPage({super.key, this.isEmbedded = false, this.onBackPressed});

  void _openDetail(BuildContext context, PropertyModel property) {
    Navigator.of(context).push(_detailRoute(context, property));
  }

  /// A recommendation was tapped: its sheet takes the place of this one.
  Route<void> _detailRoute(
    BuildContext context,
    PropertyModel property, {
    Rect? origin,
  }) {
    return PropertyDetailSheet.route(
      property,
      heroTag: 'feed_property_hero_${property.id}',
      origin: origin,
      onOpenProperty: (next, tileRect) => Navigator.of(
        context,
      ).pushReplacement(_detailRoute(context, next, origin: tileRect)),
    );
  }

  /// Their profile, opened out of their avatar at [origin]; "View on map"
  /// there goes to the home map with their listings.
  Future<void> _openOwner(
    BuildContext context,
    WidgetRef ref,
    PropertyModel property,
    Rect origin,
  ) async {
    final ownerId = property.ownerId;
    if (ownerId == null) return;
    final selection = await Navigator.of(context).push(
      PublisherProfilePage.route(
        PublisherSummary(
          id: ownerId,
          name: property.ownerName,
          avatarUrl: property.ownerAvatarUrl,
        ),
        origin: origin,
      ),
    );
    if (selection is AreaSelection) {
      ref.read(mainNavProvider.notifier).resetToHome();
      ref.read(searchAreaControllerProvider.notifier).show(selection.target);
    }
  }

  /// Pull-to-refresh: says so when there is no internet or it failed, and
  /// the old listings stay.
  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    final shownBefore = ref.read(feedProvider).hasValue;
    final ok = await ref.read(feedProvider.notifier).refresh();
    if (!shownBefore || !context.mounted) return;
    showRefreshOutcome(
      context,
      ok: ok,
      failedMessage: context.l10n.feedLoadFailed,
      onRetry: () => _refresh(context, ref),
    );
  }

  void _explore(WidgetRef ref) =>
      ref.read(mainNavProvider.notifier).resetToHome();

  Future<void> _filter(BuildContext context, WidgetRef ref) async {
    final current = ref.read(feedFiltersProvider);
    final selected = await FeedFilterSheet.show(context, current);
    if (!context.mounted ||
        selected == null ||
        mapEquals(current.toQuery(), selected.toQuery())) {
      return;
    }
    ref.read(feedFiltersProvider.notifier).state = selected;
  }

  /// Kept while another tab is shown: changes redraw it only once shown.
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      PausedWhileHidden(builder: _buildShown);

  Widget _buildShown(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(feedProvider);
    final filters = ref.watch(feedFiltersProvider);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: context.colors.background,
      // The list carries on behind a floating navigation bar, padded to end
      // above it.
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            FeedHeader(
              onBackPressed: onBackPressed,
              onExplore: () => _explore(ref),
              onFilter: () => _filter(context, ref),
              filterCount: filters.activeCount,
            ),
            Expanded(
              child: RefreshIndicator(
                color: context.colors.accent,
                onRefresh: () => _refresh(context, ref),
                child: feed.when(
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      color: context.colors.accent,
                    ),
                  ),
                  error: (error, _) => PageLoadFailure(
                    error: error,
                    message: l10n.feedLoadFailed,
                    onRetry: () => ref.read(feedProvider.notifier).refresh(),
                  ),
                  data: (page) => page.items.isEmpty
                      ? _message(
                          context,
                          FeedMessageView(
                            icon: LucideIcons.rss,
                            title: filters.isDefault
                                ? l10n.feedEmptyTitle
                                : l10n.feedNoMatches,
                            hint: filters.isDefault
                                ? l10n.feedEmptyHint
                                : l10n.feedTryOtherFilters,
                            actionLabel: filters.isDefault
                                ? l10n.feedExplore
                                : l10n.filterReset,
                            onAction: () {
                              if (filters.isDefault) {
                                _explore(ref);
                              } else {
                                ref.read(feedFiltersProvider.notifier).state =
                                    const FeedFilters();
                              }
                            },
                          ),
                        )
                      : _list(context, ref, page),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Scrollable even when short, so pull-to-refresh works on it too.
  Widget _message(BuildContext context, Widget message) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      children: [message, const AdvertisementSlot(rotationOffset: 2)],
    );
  }

  Widget _list(
    BuildContext context,
    WidgetRef ref,
    PagedList<PropertyModel> page,
  ) {
    final saved = ref.watch(savedPropertyIdsProvider).valueOrNull ?? const {};
    final advertisements = ref.watch(activeAdvertisementsProvider);
    final ads = advertisements.hasError
        ? <Advertisement>[]
        : advertisements.valueOrNull ?? <Advertisement>[];
    final hasAds = ads.isNotEmpty;
    final entries =
        page.items.length + (hasAds ? adSlotCount(page.items.length) : 0);

    return LoadMoreOnScroll(
      enabled: page.hasMore && !page.loadingMore,
      onLoadMore: () => ref.read(feedProvider.notifier).loadMore(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView.separated(
            key: ValueKey(ref.watch(feedFiltersProvider)),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              0,
              0,
              0,
              24 + MediaQuery.paddingOf(context).bottom,
            ),
            itemCount: entries + (page.loadingMore ? 1 : 0),
            separatorBuilder: (_, _) => ColoredBox(
              color: context.colors.surfaceMuted,
              child: const SizedBox(height: 8),
            ),
            itemBuilder: (context, index) {
              if (index == entries) {
                return const LoadingMoreIndicator();
              }
              final listingIndex = hasAds
                  ? listingIndexAtAdSlot(index, page.items.length)
                  : index;
              if (listingIndex == null) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: AdvertisementBanner(
                    key: ValueKey('feed-ad-${index ~/ 5}'),
                    advertisement: ads[(index ~/ 5 + 2) % ads.length],
                  ),
                );
              }
              final property = page.items[listingIndex];
              return FeedListingCard(
                key: ValueKey(property.id),
                property: property,
                isFavorite: saved.contains(property.id),
                onOpen: () => _openDetail(context, property),
                onOpenOwner: (origin) =>
                    _openOwner(context, ref, property, origin),
                onFavoriteToggled: () => ref
                    .read(savedPropertyIdsProvider.notifier)
                    .toggle(property.id),
                onViewOnMap: canShowPropertyOnMap(property)
                    ? () => showPropertyOnMap(context, ref, property)
                    : null,
              );
            },
          ),
        ),
      ),
    );
  }
}
