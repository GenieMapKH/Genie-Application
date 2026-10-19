import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/chat/models/chat_models.dart';
import 'package:genie/features/chat/models/chat_reply.dart';
import 'package:genie/l10n/l10n.dart';

/// The quoted message, shown small above a reply and above the message bar
/// while replying: who wrote it and the start of what they wrote.
class ChatReplyQuote extends StatelessWidget {
  final ChatReplyPreview quoted;

  /// "You" or the other person's name.
  final String authorName;

  const ChatReplyQuote({
    super.key,
    required this.quoted,
    required this.authorName,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: context.colors.border.withValues(alpha: 0.5),
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: context.colors.accent),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      Text(
                        quotedText(context, quoted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: context.colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The text, or what kind of message it is when it has none.
  static String quotedText(BuildContext context, ChatReplyPreview quoted) {
    final l10n = context.l10n;
    final attachment = quoted.attachment;
    if (quoted.text == ChatMessage.undecryptableText) {
      return l10n.chatUndecryptable;
    }
    if (quoted.text.isNotEmpty) return quoted.text;
    if (attachment == null) return '';
    if (attachment.isVoice) return l10n.chatPreviewVoice;
    if (attachment.isImage) return l10n.chatPreviewPhoto;
    return '\u{1F4CE} ${attachment.name}';
  }
}
