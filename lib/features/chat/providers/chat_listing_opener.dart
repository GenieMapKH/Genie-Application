import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens listing [listingId] from a card in a conversation.
typedef ChatListingOpener =
    Future<void> Function(BuildContext context, String listingId);

/// The listing page belongs to another feature, which itself opens chats, so
/// chat does not import it: the app supplies this at start-up (see
/// `lib/app/navigation`). Null (in tests) leaves the card untappable.
final chatListingOpenerProvider = Provider<ChatListingOpener?>((ref) => null);
