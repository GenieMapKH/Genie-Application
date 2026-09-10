import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/presentation/view_models/property_providers.dart';
import 'package:genie/shared/utils/app_popup.dart';

class PropertyOptionsSheet {
  static void show(BuildContext context, WidgetRef ref, PropertyModel property) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              if (isDraft)
                ListTile(
                  leading: const Icon(Icons.public, color: Color(0xFF5B5FEF)),
                  title: const Text('Publish to Public'),
                  onTap: () {
                    Navigator.pop(context);
                    _changePropertyStatus(context, ref, property.id, true);
                  },
                )
              else
                ListTile(
                  leading: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFF5B5FEF),
                  ),
                  title: const Text('Move to Draft'),
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
                title: const Text(
                  'Delete Property',
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

  static Future<void> _changePropertyStatus(BuildContext context, WidgetRef ref, String id, bool publish) async {
    try {
      if (publish) {
        await ref.read(propertiesProvider.notifier).publishProperty(id);
      } else {
        await ref.read(propertiesProvider.notifier).unpublishProperty(id);
      }
      if (context.mounted) {
        AppPopup.showSuccess(
          context,
          publish ? 'Property published' : 'Property moved to draft',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppPopup.showError(context, 'Failed to update property status: $e');
      }
    }
  }

  static Future<void> _deleteProperty(BuildContext context, WidgetRef ref, String id) async {
    try {
      await ref.read(propertiesProvider.notifier).removeProperty(id);
      if (context.mounted) {
        AppPopup.showSuccess(context, 'Property deleted');
      }
    } catch (e) {
      if (context.mounted) {
        AppPopup.showError(context, 'Failed to delete property: $e');
      }
    }
  }
}
