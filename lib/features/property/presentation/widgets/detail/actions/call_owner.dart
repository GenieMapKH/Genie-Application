import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/utils/app_popup.dart';

/// The number "Call Now" dials: the one written on the listing, else the
/// owner's own. Null for a guest, who is never sent either.
String? callNumberOf(PropertyModel property) {
  for (final number in [property.details.contactPhone, property.ownerPhone]) {
    final trimmed = number?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  }
  return null;
}

/// Opens the phone app on the listing's number, or says why it cannot.
Future<void> callOwner(BuildContext context, PropertyModel property) async {
  final number = callNumberOf(property);
  if (number == null) {
    AppPopup.showInfo(context, context.l10n.propertyNoPhoneNumber);
    return;
  }

  final uri = Uri(scheme: 'tel', path: number.replaceAll(RegExp(r'\s'), ''));
  try {
    if (await launchUrl(uri)) return;
  } catch (e, stackTrace) {
    AppLogger.error('The phone app could not be opened', e, stackTrace);
  }
  if (context.mounted) {
    AppPopup.showError(context, context.l10n.propertyCallFailed);
  }
}
