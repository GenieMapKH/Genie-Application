import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/features/chat/models/chat_models.dart';
import 'package:genie/features/chat/presentation/widgets/conversation/chat_image_attachment.dart';
import 'package:genie/features/chat/presentation/widgets/conversation/chat_reply_quote.dart';
import 'package:genie/features/chat/presentation/widgets/voice/chat_voice_message.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/features/chat/presentation/widgets/conversation/chat_listing_card.dart';

/// One message in a conversation: the user's own on the right, the other
/// person's on the left. A reply shows the message it quotes above it, and
/// an edited message says so below.
class ChatMessageBubble extends StatelessWidget {
  static const _corner = Radius.circular(16);
  static const _tail = Radius.circular(4);

  final ChatMessage message;
  final bool isMine;

  /// Called when the user taps a message that failed to send.
  final VoidCallback? onRetry;

  /// Who wrote the quoted message: "You" or the other person's name.
  final String quotedAuthorName;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.onRetry,
    this.quotedAuthorName = '',
  });

  @override
  Widget build(BuildContext context) {
    final failed = message.status == ChatMessageStatus.failed;
    final attachment = message.attachment;
    final hasPicture =
        message.localImage != null || (attachment?.isImage ?? false);
    final voice = message.voice;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (message.replyTo case final quoted?)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: ChatReplyQuote(
                  quoted: quoted,
                  authorName: quotedAuthorName,
                ),
              ),
            if (hasPicture)
              Padding(
                padding: EdgeInsets.only(bottom: message.text.isEmpty ? 0 : 6),
                child: ChatImageAttachment(
                  message: message,
                  onTap: failed ? onRetry : null,
                ),
              ),
            if (voice != null)
              ChatVoiceMessage(
                message: message,
                voice: voice,
                isMine: isMine,
                onTap: failed ? onRetry : null,
              )
            else if (attachment != null && !attachment.isImage)
              _buildText(context, '\u{1F4CE} ${attachment.name}', failed),
            if (message.listing case final listing?)
              ChatListingCard(
                listing: listing,
                onRetry: failed ? onRetry : null,
              )
            else if (message.text.isNotEmpty)
              _buildText(
                context,
                message.text == ChatMessage.undecryptableText
                    ? context.l10n.chatUndecryptable
                    : message.text,
                failed,
              ),
            if (message.editedAt != null &&
                message.status == ChatMessageStatus.sent)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  context.l10n.chatEdited,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: context.colors.textHint,
                  ),
                ),
              ),
            if (message.status != ChatMessageStatus.sent)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  failed
                      ? context.l10n.chatMessageNotSent
                      : context.l10n.chatMessageSending,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: failed
                        ? const Color(0xFFDC2626)
                        : context.colors.textHint,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildText(BuildContext context, String text, bool failed) {
    return GestureDetector(
      onTap: failed ? onRetry : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMine ? context.colors.accent : context.colors.surface,
          border: isMine ? null : Border.all(color: context.colors.border),
          borderRadius: BorderRadius.only(
            topLeft: _corner,
            topRight: _corner,
            bottomLeft: isMine ? _corner : _tail,
            bottomRight: isMine ? _tail : _corner,
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isMine
                ? context.colors.onPrimary
                : context.colors.textPrimary,
          ),
        ),
      ),
    );
  }
}
