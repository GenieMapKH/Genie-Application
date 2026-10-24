import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/feed/presentation/view_models/feed_provider.dart';
import 'package:genie/features/feed/presentation/widgets/feed_listing_card.dart';
import 'package:genie/features/feed/presentation/widgets/feed_message_view.dart';
import 'package:genie/features/home/presentation/providers/main_nav_provider.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/presentation/view_models/saved_property_ids_provider.dart';
import 'package:genie/features/property/presentation/widgets/detail/property_detail_sheet.dart';
import 'package:genie/features/search/data/models/publisher_summary.dart';
import 'package:genie/features/search/presentation/screens/publisher_profile_page.dart';
import 'package:genie/features/search/presentation/view_models/search_area_controller.dart';
import 'package:genie/features/search/presentation/view_models/search_selection.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/shared/utils/app_popup.dart';
import 'package:genie/shared/utils/paged_list.dart';
import 'package:genie/shared/widgets/layout/app_header_bar.dart';
import 'package:genie/shared/widgets/layout/paused_while_hidden.dart';
import 'package:genie/shared/widgets/lists/load_more_on_scroll.dart';
import 'package:genie/shared/widgets/lists/loading_more_indicator.dart';

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
      heroTag: 'saved_property_hero_${property.id}',
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

  /// Pull-to-refresh: says so when it failed and the old listings stay.
  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    final shownBefore = ref.read(feedProvider).hasValue;
    final ok = await ref.read(feedProvider.notifier).refresh();
    if (!ok && shownBefore && context.mounted) {
      AppPopup.showError(context, context.l10n.feedLoadFailed);
    }
  }

  void _explore(WidgetRef ref) =>
      ref.read(mainNavProvider.notifier).resetToHome();

  /// Kept while another tab is shown: changes redraw it only once shown.
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      PausedWhileHidden(builder: _buildShown);

  Widget _buildShown(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(feedProvider);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppHeaderBar(title: l10n.feedTitle, onBackPressed: onBackPressed),
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
                  error: (_, _) => _message(
                    FeedMessageView(
                      icon: Icons.cloud_off_rounded,
                      title: l10n.feedLoadFailed,
                      actionLabel: l10n.commonRetry,
                      onAction: () => ref.read(feedProvider.notifier).refresh(),
                    ),
                  ),
                  data: (page) => page.items.isEmpty
                      ? _message(
                          FeedMessageView(
                            icon: Icons.dynamic_feed_rounded,
                            title: l10n.feedEmptyTitle,
                            hint: l10n.feedEmptyHint,
                            actionLabel: l10n.feedExplore,
                            onAction: () => _explore(ref),
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
  Widget _message(Widget message) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [message],
    );
  }

  Widget _list(
    BuildContext context,
    WidgetRef ref,
    PagedList<PropertyModel> page,
  ) {
    final saved = ref.watch(savedPropertyIdsProvider).valueOrNull ?? const {};

    return LoadMoreOnScroll(
      enabled: page.hasMore && !page.loadingMore,
      onLoadMore: () => ref.read(feedProvider.notifier).loadMore(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: page.items.length + (page.loadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 24),
        itemBuilder: (context, index) {
          if (index == page.items.length) return const LoadingMoreIndicator();
          final property = page.items[index];
          return FeedListingCard(
            property: property,
            isFavorite: saved.contains(property.id),
            onOpen: () => _openDetail(context, property),
            onOpenOwner: (origin) => _openOwner(context, ref, property, origin),
            onFavoriteToggled: () =>
                ref.read(savedPropertyIdsProvider.notifier).toggle(property.id),
          );
        },
      ),
    );
  }
}
