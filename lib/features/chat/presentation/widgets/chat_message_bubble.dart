import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/features/chat/models/chat_models.dart';

/// One message in a conversation: the user's own on the right, the other
/// person's on the left.
class ChatMessageBubble extends StatelessWidget {
  static const _accent = Color(0xFF5B5FEF);
  static const _corner = Radius.circular(16);
  static const _tail = Radius.circular(4);

  final ChatMessage message;
  final bool isMine;

  /// Called when the user taps a message that failed to send.
  final VoidCallback? onRetry;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final failed = message.status == ChatMessageStatus.failed;

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
            GestureDetector(
              onTap: failed ? onRetry : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isMine ? _accent : Colors.white,
                  border: isMine
                      ? null
                      : Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.only(
                    topLeft: _corner,
                    topRight: _corner,
                    bottomLeft: isMine ? _corner : _tail,
                    bottomRight: isMine ? _tail : _corner,
                  ),
                ),
                child: Text(
                  message.text,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isMine ? Colors.white : const Color(0xFF111827),
                  ),
                ),
              ),
            ),
            if (message.status != ChatMessageStatus.sent)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  failed ? 'Not sent. Tap to retry.' : 'Sending…',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: failed
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
