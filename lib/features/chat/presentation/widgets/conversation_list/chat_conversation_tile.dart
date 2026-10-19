import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/chat/models/chat_models.dart';
import 'package:genie/shared/utils/owner_display_name.dart';
import 'package:genie/shared/widgets/media/user_avatar.dart';
import 'package:genie/l10n/l10n.dart';

/// One conversation in a chat list: picture, name, last message, time and
/// unread count.
class ChatConversationTile extends StatelessWidget {
  final ChatConversation chat;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const ChatConversationTile({
    super.key,
    required this.chat,
    required this.onTap,
    required this.onLongPress,
  });

  /// The last message, with the stand-ins for one not decrypted yet, for a
  /// picture and for a voice message in the user's language.
  String _preview(BuildContext context) {
    return switch (chat.lastMessage) {
      ChatConversation.encryptedPreview => context.l10n.chatPreviewEncrypted,
      ChatConversation.photoPreview => context.l10n.chatPreviewPhoto,
      ChatConversation.voicePreview => context.l10n.chatPreviewVoice,
      final text => text,
    };
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserAvatar(
              name: chat.participantName,
              avatarUrl: chat.participantAvatar,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ownerDisplayName(context.l10n, chat.participantName),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _preview(context),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: context.colors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  chat.lastMessageTime,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                if (chat.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: context.colors.highlight,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      chat.unreadCount.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: context.colors.onHighlight,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
