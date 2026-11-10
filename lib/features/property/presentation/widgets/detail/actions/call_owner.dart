import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/utils/app_popup.dart';
import 'package:tilomnov/shared/widgets/lists/option_sheet.dart';

enum PropertyCallMethod { inApp, phone }

/// Ask each time; dismissing the sheet places no call.
Future<PropertyCallMethod?> choosePropertyCallMethod(
  BuildContext context,
) async {
  final choice = await showOptionSheet<PropertyCallMethod?>(
    context,
    title: context.l10n.propertyCallNow,
    selected: null,
    options: [
      SheetOption(PropertyCallMethod.inApp, context.l10n.propertyCallInApp),
      SheetOption(PropertyCallMethod.phone, context.l10n.propertyCallPhone),
    ],
  );
  return choice?.value;
}

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
  var number = callNumberOf(property);
  if (number == null) {
    AppPopup.showInfo(context, context.l10n.propertyNoPhoneNumber);
    return;
  }

  final numbers = {
    number,
    ...property.details.additionalContactPhones,
  }.toList();
  if (numbers.length > 1) {
    final picked = await showOptionSheet<String?>(
      context,
      title: context.l10n.propertyCallPhone,
      selected: null,
      options: [for (final phone in numbers) SheetOption(phone, phone)],
    );
    if (picked?.value == null || !context.mounted) return;
    number = picked!.value!;
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
