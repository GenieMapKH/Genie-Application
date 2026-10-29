import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/chat/models/chat_listing.dart';
import 'package:tilomnov/features/chat/presentation/widgets/conversation/chat_listing_preview.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// Above the message bar when the chat was opened from a listing: the
/// listing, with a button to send it, so the owner knows which one the
/// buyer means. Closed with the cross, or once sent.
class ChatListingOfferBar extends StatelessWidget {
  final ChatListing listing;
  final VoidCallback onSend;
  final VoidCallback onDismiss;

  const ChatListingOfferBar({
    super.key,
    required this.listing,
    required this.onSend,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.chatAskAboutListing,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textMuted,
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.chatDismissListing,
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close, size: 18, color: colors.textMuted),
                onPressed: onDismiss,
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: ChatListingPreview(listing: listing)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ElevatedButton.icon(
                  onPressed: onSend,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: colors.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.send_outlined, size: 16),
                  label: Text(l10n.chatSendListing),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
