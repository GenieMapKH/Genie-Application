import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/shared/widgets/layout/app_header_bar.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/presentation/property_list_layout.dart';
import 'package:tilomnov/features/property/presentation/screens/add_property/add_property_page.dart';
import 'package:tilomnov/features/property/presentation/view_models/own_listings.dart';
import 'package:tilomnov/features/property/presentation/view_models/own_listings_providers.dart';

import 'package:tilomnov/features/property/presentation/widgets/my_properties/property_card.dart';
import 'package:tilomnov/features/property/presentation/widgets/my_properties/empty_properties_state.dart';
import 'package:tilomnov/features/property/presentation/widgets/my_properties/property_edit_route.dart';
import 'package:tilomnov/features/property/presentation/widgets/my_properties/property_options_sheet.dart';
import 'package:tilomnov/features/property/presentation/widgets/my_properties/property_tabs.dart';
import 'package:tilomnov/features/property/presentation/widgets/my_properties/property_bottom_bar.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/layout/paused_while_hidden.dart';
import 'package:tilomnov/shared/widgets/lists/load_more_on_scroll.dart';
import 'package:tilomnov/shared/widgets/feedback/page_load_failure.dart';
import 'package:tilomnov/shared/widgets/feedback/refresh_outcome.dart';
import 'package:tilomnov/shared/widgets/lists/loading_more_indicator.dart';

class MyPropertiesPage extends ConsumerWidget {
  final bool isEmbedded;
  final VoidCallback? onBackPressed;

  const MyPropertiesPage({
    super.key,
    this.isEmbedded = false,
    this.onBackPressed,
  });

  /// Kept while another tab is shown: changes to the listings redraw it
  /// only once it is shown again.
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      PausedWhileHidden(builder: _buildShown);

  Widget _buildShown(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(propertiesProvider);
    // With nothing loaded before, the failure takes the page's place.
    final failed = propertiesAsync.hasError && !propertiesAsync.hasValue;

    return Scaffold(
      backgroundColor: context.colors.background,
      // The list carries on behind a floating navigation bar, padded to end
      // above it.
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeaderBar(
              title: context.l10n.navMyProperties,
              onBackPressed: onBackPressed,
            ),
            // The failure sits right under the header, as on every tab.
            if (!failed) const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                color: context.colors.accent,
                onRefresh: () => _refresh(context, ref),
                child: propertiesAsync.when(
                  skipLoadingOnReload: true,
                  skipError: true,
                  data: (listings) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PropertyTabs(countByStatus: listings.countByStatus),
                      const SizedBox(height: 24),
                      Expanded(child: _buildBody(context, ref, listings)),
                    ],
                  ),
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      color: context.colors.accent,
                    ),
                  ),
                  error: (error, stack) =>
                      _buildErrorState(context, ref, error),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isEmbedded ? null : const PropertyBottomBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: isEmbedded ? 20.0 : 70.0),
        child: SizedBox(
          width: 140,
          height: 44,
          child: ElevatedButton(
            // Saving it reloads the list (see `ownListingsChanged`).
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    const AddPropertyPage(boundaryPoints: [], propertyArea: 0),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              elevation: 4,
            ),
            child: Text(
              context.l10n.propertyAddProperty,
              style: GoogleFonts.inter(
                color: context.colors.onPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, OwnListings listings) {
    final properties = listings.items;
    if (properties.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        children: const [EmptyPropertiesState()],
      );
    }

    final page = listings.page;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Phones keep one card per row; tablets fit as many as they can.
        final columns = PropertyListLayout.isTablet(context)
            ? PropertyListLayout.columnCount(
                constraints.maxWidth - 32,
                PropertyListLayout.ownCardMaxWidth,
              )
            : 1;
        final rowCount = (properties.length / columns).ceil();
        return LoadMoreOnScroll(
          enabled: page.hasMore && !page.loadingMore,
          onLoadMore: () => ref.read(propertiesProvider.notifier).loadMore(),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              MediaQuery.paddingOf(context).bottom,
            ),
            itemCount: rowCount + (page.loadingMore ? 1 : 0),
            itemBuilder: (context, row) {
              if (row == rowCount) return const LoadingMoreIndicator();
              return _buildCardRow(context, ref, properties, row, columns);
            },
          ),
        );
      },
    );
  }

  /// One row of [columns] cards; the last row keeps empty slots so its cards
  /// are as wide as the ones above.
  Widget _buildCardRow(
    BuildContext context,
    WidgetRef ref,
    List<PropertyModel> properties,
    int row,
    int columns,
  ) {
    if (columns == 1) return _buildCard(context, ref, properties[row]);
    final start = row * columns;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var column = 0; column < columns; column++) ...[
          if (column > 0)
            const SizedBox(width: PropertyListLayout.columnSpacing),
          Expanded(
            child: start + column < properties.length
                ? _buildCard(context, ref, properties[start + column])
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }

  Widget _buildCard(
    BuildContext context,
    WidgetRef ref,
    PropertyModel property,
  ) {
    return PropertyCard(
      property: property,
      onTap: (cardRect) => Navigator.of(context).push(
        PropertyEditRoute(
          origin: cardRect,
          page: AddPropertyPage.edit(property),
        ),
      ),
      onOptionsTapped: () => PropertyOptionsSheet.show(context, ref, property),
    );
  }

  /// Pull-to-refresh: the listings shown stay; says so when there is no
  /// internet or they could not be read.
  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    final shownBefore = ref.read(propertiesProvider).hasValue;
    final ok = await ref.read(propertiesProvider.notifier).refresh();
    if (!shownBefore || !context.mounted) return;
    showRefreshOutcome(
      context,
      ok: ok,
      failedMessage: context.l10n.propertyCouldNotLoadProperties,
      onRetry: () => _refresh(context, ref),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return PageLoadFailure(
      error: error,
      message: context.l10n.propertyCouldNotLoadProperties,
      onRetry: () => ref.read(propertiesProvider.notifier).refresh(),
    );
  }
}
