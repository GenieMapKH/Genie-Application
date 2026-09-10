import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/presentation/screens/sort_order_page.dart';
import 'package:genie/features/property/presentation/view_models/saved_properties_provider.dart';
import 'package:genie/features/property/presentation/widgets/detail/property_detail_sheet.dart';
import 'package:genie/features/property/presentation/widgets/saved_property_card.dart';

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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
                    onPressed: () {
                      if (onBackPressed != null) {
                        onBackPressed!();
                      } else {
                        Navigator.of(context).maybePop();
                      }
                    },
                  ),
                  Expanded(
                    child: Text(
                      'Saved Properties',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ),
                  Text(
                    '$count Saved',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF5B5FEF),
                    ),
                  ),
                ],
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
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.tune,
                          size: 16,
                          color: Color(0xFF4B5563),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Sort by',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF374151),
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
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF5B5FEF)),
                ),
                error: (err, stack) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Failed to load saved properties',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          ref.read(savedPropertiesProvider.notifier).refresh();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (_) {
                  if (sortedProperties.isEmpty) {
                    return _buildEmptyState();
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
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 36,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "You haven't saved any properties yet.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Tap the heart icon on listings to save them for later.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ],
            ),
          ],
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
        childAspectRatio: 0.58,
      ),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final property = properties[index];
        return SavedPropertyCard(
          property: property,
          isFavorite: true,
          onTap: () => _openDetail(context, property),
          onFavoriteToggled: () {
            ref
                .read(savedPropertiesProvider.notifier)
                .toggleFavorite(property);
          },
        );
      },
    );
  }
}
