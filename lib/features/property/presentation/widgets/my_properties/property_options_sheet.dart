import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/presentation/view_models/own_listings_providers.dart';
import 'package:genie/shared/utils/app_popup.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/core/logging/app_logger.dart';

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
        final isDraft = property.status == 'Draft';
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
              if (isDraft)
                ListTile(
                  leading: Icon(Icons.public, color: context.colors.accent),
                  title: Text(context.l10n.propertyPublishToPublic),
                  onTap: () {
                    Navigator.pop(context);
                    _changePropertyStatus(context, ref, property.id, true);
                  },
                )
              else
                ListTile(
                  leading: Icon(
                    Icons.lock_outline,
                    color: context.colors.accent,
                  ),
                  title: Text(context.l10n.propertyMoveToDraft),
                  onTap: () {
                    Navigator.pop(context);
                    _changePropertyStatus(context, ref, property.id, false);
                  },
                ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
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

  static Future<void> _changePropertyStatus(
    BuildContext context,
    WidgetRef ref,
    String id,
    bool publish,
  ) async {
    try {
      if (publish) {
        await ref.read(propertiesProvider.notifier).publishProperty(id);
      } else {
        await ref.read(propertiesProvider.notifier).unpublishProperty(id);
      }
      if (context.mounted) {
        AppPopup.showSuccess(
          context,
          publish
              ? context.l10n.propertyPublishedToast
              : context.l10n.propertyMovedToDraft,
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Could not change the property status', e, stackTrace);
      if (context.mounted) {
        AppPopup.showError(context, context.l10n.propertyUpdateFailed);
      }
    }
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
        AppPopup.showError(context, context.l10n.propertyDeleteFailed);
      }
    }
  }
}
