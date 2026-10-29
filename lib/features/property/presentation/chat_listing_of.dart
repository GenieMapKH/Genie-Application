import 'package:tilomnov/features/chat/models/chat_listing.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/utils/property_format.dart';
import 'package:tilomnov/l10n/generated/app_localizations.dart';

/// [property] as a card to send in a chat: its first photo (the small copy)
/// and the price its cards show, in the sender's words.
ChatListing chatListingOf(AppLocalizations l10n, PropertyModel property) {
  final photos = property.cardImageUrls;
  return ChatListing(
    id: property.id,
    title: property.title,
    price: PropertyFormat.cardPrice(l10n, property),
    imageUrl: photos.isEmpty ? null : photos.first,
  );
}
