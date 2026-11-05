import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/presentation/view_models/own_listings_providers.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_visibility.dart';
import 'package:tilomnov/features/property/presentation/widgets/detail/actions/property_visibility_sheet.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/utils/app_popup.dart';
import 'package:tilomnov/shared/widgets/feedback/failure_message.dart';

/// The Status button on a My Properties card: lets the owner make the
/// listing public, a draft or sold, and says how that went.
class PropertyStatusChange {
  const PropertyStatusChange._();

  static Future<void> pick(
    BuildContext context,
    WidgetRef ref,
    PropertyModel property,
  ) async {
    final status = property.status;
    final target = await PropertyVisibilitySheet.show(context, status);
    if (target == null || visibilityChange(status, target) == null) return;
    try {
      await ref
          .read(propertiesProvider.notifier)
          .changeVisibility(property.id, status, target);
      if (context.mounted) {
        AppPopup.showSuccess(context, context.l10n.propertyVisibilityChanged);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Could not change the property status', e, stackTrace);
      if (context.mounted) {
        showFailure(
          context,
          error: e,
          fallback: context.l10n.propertyCouldNotChangeVisibility,
        );
      }
    }
  }
}
