import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/presentation/widgets/detail/property_detail_sheet.dart';
import 'package:tilomnov/features/property/presentation/widgets/saved_property_card.dart';
import 'package:tilomnov/features/property/presentation/property_list_layout.dart';

void openAdminProperty(
  BuildContext context,
  Map<String, dynamic> property, {
  String? heroTag,
}) {
  Navigator.of(context, rootNavigator: true).push(
    PropertyDetailSheet.route(
      PropertyModel.fromJson(property),
      heroTag: heroTag,
    ),
  );
}

class AdminPropertyCard extends StatelessWidget {
  final Map<String, dynamic> property;
  final int? reportCount;
  final VoidCallback? onTap;
  const AdminPropertyCard({
    super.key,
    required this.property,
    this.reportCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final listing = PropertyModel.fromJson({
      ...property,
      'user': property['user'] ?? property['account'],
    });
    final heroTag =
        'admin_property_${identityHashCode(ModalRoute.of(context))}_${listing.id}';
    return Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: PropertyListLayout.savedCardMaxWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AspectRatio(
            aspectRatio: 0.68,
            child: Stack(
              fit: StackFit.expand,
              children: [
                SavedPropertyCard(
                  property: listing,
                  heroTag: heroTag,
                  isFavorite: false,
                  allowNonPublic: true,
                  onTap:
                      onTap ??
                      () => openAdminProperty(
                        context,
                        property,
                        heroTag: heroTag,
                      ),
                ),
                if (reportCount != null)
                  Positioned(
                    top: 48,
                    right: 10,
                    child: IgnorePointer(
                      child: Chip(
                        avatar: const Icon(LucideIcons.flag, size: 18),
                        label: Text('$reportCount reports'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
