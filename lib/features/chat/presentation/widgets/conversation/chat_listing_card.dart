import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/chat/models/chat_listing.dart';
import 'package:genie/features/chat/presentation/widgets/conversation/chat_listing_preview.dart';
import 'package:genie/features/chat/providers/chat_listing_opener.dart';
import 'package:genie/l10n/l10n.dart';

/// A listing sent in a conversation, so both people know which one they talk
/// about. Tapping it opens the listing.
class ChatListingCard extends ConsumerWidget {
  final ChatListing listing;

  /// Called instead of opening it, for a message that failed to send.
  final VoidCallback? onRetry;

  const ChatListingCard({super.key, required this.listing, this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final open = ref.watch(chatListingOpenerProvider);
    final onTap =
        onRetry ?? (open == null ? null : () => open(context, listing.id));

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: ChatListingPreview(
            listing: listing,
            footer: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                context.l10n.chatViewListing,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.accent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
