import 'package:flutter/material.dart';
import 'package:tilomnov/features/payment/presentation/renewal_checkout.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/presentation/view_models/own_listings_providers.dart';
import 'package:tilomnov/features/property/presentation/widgets/detail/actions/property_visibility_sheet.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/utils/app_popup.dart';

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
    final target = await PropertyVisibilitySheet.show(
      context,
      status,
      onPaymentRequired: () => renewProperty(context, ref, property),
      onChanged: (target) => ref
          .read(propertiesProvider.notifier)
          .changeVisibility(property.id, status, target),
    );
    if (target != null && context.mounted) {
      AppPopup.showSuccess(context, context.l10n.propertyVisibilityChanged);
    }
  }
}
