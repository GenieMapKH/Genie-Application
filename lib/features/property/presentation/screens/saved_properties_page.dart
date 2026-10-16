import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/shared/widgets/app_header_bar.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/presentation/screens/sort_order_page.dart';
import 'package:genie/features/property/presentation/view_models/saved_properties_provider.dart';
import 'package:genie/features/property/presentation/widgets/detail/property_detail_sheet.dart';
import 'package:genie/features/property/presentation/widgets/saved_property_card.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';

/// The Saved Properties tab page matching Screenshots 1 & 2.
class SavedPropertiesPage extends ConsumerWidget {
  final bool isEmbedded;
  final VoidCallback? onBackPressed;

  const SavedPropertiesPage({
    super.key,
    this.isEmbedded = false,
    this.onBackPressed,
  });

  void _openDetail(BuildContext context, PropertyModel property) {
    Navigator.of(context).push(
      PropertyDetailSheet.route(
        property,
        heroTag: 'saved_property_hero_${property.id}',
        onOpenProperty: (next) {
          Navigator.of(context).pop();
          _openDetail(context, next);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedPropertiesProvider);
    final sortedProperties = ref.watch(sortedSavedPropertiesProvider);
    final count = savedAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar Header
            AppHeaderBar(
              title: context.l10n.propertySavedProperties,
              onBackPressed: onBackPressed,
              trailing: Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: Text(
                  '$count Saved',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.colors.accent,
                  ),
                ),
              ),
            ),

            // Sort By Filter Pill Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(SortOrderPage.route());
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.divider,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tune,
                          size: 16,
                          color: context.colors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          context.l10n.propertySortBy,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Main Content Area
            Expanded(
              child: savedAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: context.colors.accent,
                  ),
                ),
                error: (err, stack) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.propertyFailedToLoadSavedProperties,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: context.colors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          ref.read(savedPropertiesProvider.notifier).refresh();
                        },
                        child: Text(context.l10n.commonRetry),
                      ),
                    ],
                  ),
                ),
                data: (_) {
                  if (sortedProperties.isEmpty) {
                    return _buildEmptyState(context);
                  }
                  return _buildPropertyList(context, ref, sortedProperties);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty state matching Screenshot 2.
  Widget _buildEmptyState(BuildContext context) {
    // Aligned to the top so the card hugs its content instead of filling the
    // page, like the empty My Properties and chat lists.
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          decoration: BoxDecoration(
            color: context.colors.surfaceMuted,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_border_rounded,
                  size: 36,
                  color: context.colors.textHint,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.propertyYouHavenTSavedAnyProperties,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: context.colors.textHint,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      context.l10n.propertyTapTheHeartIconOnListings,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: context.colors.textHint,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Grid view matching Screenshot 1.
  Widget _buildPropertyList(
    BuildContext context,
    WidgetRef ref,
    List<PropertyModel> properties,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final property = properties[index];
        return SavedPropertyCard(
          property: property,
          isFavorite: true,
          onTap: () => _openDetail(context, property),
          onFavoriteToggled: () {
            ref.read(savedPropertiesProvider.notifier).toggleFavorite(property);
          },
        );
      },
    );
  }
}
