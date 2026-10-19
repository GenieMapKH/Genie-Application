import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/chat/models/chat_composer_mode.dart';
import 'package:genie/features/chat/presentation/widgets/conversation/chat_reply_quote.dart';
import 'package:genie/l10n/l10n.dart';

/// Above the message bar while replying or editing: which message, and a
/// button to go back to writing a new one.
class ChatComposerBanner extends StatelessWidget {
  final ChatComposerMode mode;

  /// "You" or the other person's name: who wrote the message replied to.
  final String authorName;
  final VoidCallback onCancel;

  const ChatComposerBanner({
    super.key,
    required this.mode,
    required this.authorName,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (icon, title) = switch (mode) {
      ReplyingTo() => (Icons.reply, l10n.chatReplyingTo(authorName)),
      EditingMessage() => (Icons.edit_outlined, l10n.chatEditingMessage),
    };

    return Container(
      color: context.colors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.colors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                  ),
                ),
                Text(
                  ChatReplyQuote.quotedText(
                    context,
                    mode.message.asReplyPreview,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: context.colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.commonCancel,
            icon: Icon(Icons.close, color: context.colors.textMuted),
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}
