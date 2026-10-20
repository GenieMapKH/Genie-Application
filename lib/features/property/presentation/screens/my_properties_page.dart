import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/shared/widgets/layout/app_header_bar.dart';
import 'package:genie/features/property/presentation/screens/add_property/add_property_page.dart';
import 'package:genie/features/property/presentation/view_models/own_listings.dart';
import 'package:genie/features/property/presentation/view_models/own_listings_providers.dart';

import 'package:genie/features/property/presentation/widgets/my_properties/property_card.dart';
import 'package:genie/features/property/presentation/widgets/my_properties/empty_properties_state.dart';
import 'package:genie/features/property/presentation/widgets/my_properties/property_options_sheet.dart';
import 'package:genie/features/property/presentation/widgets/my_properties/property_tabs.dart';
import 'package:genie/features/property/presentation/widgets/my_properties/property_bottom_bar.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/shared/widgets/lists/load_more_on_scroll.dart';
import 'package:genie/shared/widgets/lists/loading_more_indicator.dart';

class MyPropertiesPage extends ConsumerWidget {
  final bool isEmbedded;
  final VoidCallback? onBackPressed;

  const MyPropertiesPage({
    super.key,
    this.isEmbedded = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(propertiesProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeaderBar(
              title: context.l10n.navMyProperties,
              onBackPressed: onBackPressed,
            ),
            if (propertiesAsync.hasError &&
                propertiesAsync.hasValue &&
                !propertiesAsync.isLoading)
              _buildOfflineWarning(context),
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                color: context.colors.accent,
                onRefresh: () =>
                    ref.read(propertiesProvider.notifier).refresh(),
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
                  error: (error, stack) => _buildErrorState(context, ref),
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
        children: const [EmptyPropertiesState()],
      );
    }

    final page = listings.page;
    return LoadMoreOnScroll(
      enabled: page.hasMore && !page.loadingMore,
      onLoadMore: () => ref.read(propertiesProvider.notifier).loadMore(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: properties.length + (page.loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == properties.length) return const LoadingMoreIndicator();
          final property = properties[index];
          return PropertyCard(
            property: property,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AddPropertyPage.edit(property),
              ),
            ),
            onOptionsTapped: () =>
                PropertyOptionsSheet.show(context, ref, property),
          );
        },
      ),
    );
  }

  Widget _buildOfflineWarning(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: context.colors.dangerSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colors.dangerBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, size: 16, color: Color(0xFFEF4444)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.propertyYouAreOfflinePleaseConnectTo,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: context.colors.onDangerSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: context.colors.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.propertyCouldNotLoadProperties,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: context.colors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () =>
                        ref.read(propertiesProvider.notifier).refresh(),
                    child: Text(
                      context.l10n.commonRetry,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.colors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
