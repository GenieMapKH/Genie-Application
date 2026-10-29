import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/features/chat/providers/chat_listing_opener.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_providers.dart';
import 'package:tilomnov/features/property/presentation/widgets/detail/property_detail_sheet.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/utils/app_popup.dart';

/// Lets a listing card in a conversation open the listing. The listing page
/// opens chats itself, so chat reaches it through this, supplied by the app.
ChatListingOpener listingFromChatOpener(Ref ref) {
  return (context, listingId) async {
    final navigator = Navigator.of(context);
    final l10n = context.l10n;
    try {
      final property = await ref
          .read(propertyRepositoryProvider)
          .fetchPropertyDetail(listingId);
      await navigator.push(PropertyDetailSheet.route(property));
    } catch (e, stackTrace) {
      // Sold, taken down or deleted since it was sent.
      AppLogger.error(
        'A listing from a chat could not be opened',
        e,
        stackTrace,
      );
      if (context.mounted) {
        AppPopup.showError(context, l10n.chatListingUnavailable);
      }
    }
  };
}
