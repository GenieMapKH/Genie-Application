import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/presentation/view_models/own_listings_providers.dart';
import 'package:tilomnov/shared/utils/app_popup.dart';
import 'package:tilomnov/shared/widgets/feedback/failure_message.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/core/logging/app_logger.dart';

/// What a long press on a My Properties card offers: deleting the listing.
/// Status and insights have their own buttons on the card.
class PropertyOptionsSheet {
  static void show(
    BuildContext context,
    WidgetRef ref,
    PropertyModel property,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  LucideIcons.trash2,
                  color: Color(0xFFE5484D),
                ),
                title: Text(
                  context.l10n.propertyDeleteProperty,
                  style: TextStyle(color: Color(0xFFE5484D)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteProperty(context, ref, property.id);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  static Future<void> _deleteProperty(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    try {
      await ref.read(propertiesProvider.notifier).removeProperty(id);
      if (context.mounted) {
        AppPopup.showSuccess(context, context.l10n.propertyPropertyDeleted);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Could not delete the property', e, stackTrace);
      if (context.mounted) {
        showFailure(
          context,
          error: e,
          fallback: context.l10n.propertyDeleteFailed,
        );
      }
    }
  }
}
