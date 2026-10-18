import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/shared/widgets/media/user_avatar.dart';
import 'package:genie/features/chat/presentation/widgets/conversation/chat_participant_sheet.dart';
import 'package:genie/features/chat/presentation/widgets/conversation/chat_presence_label.dart';
import 'package:genie/features/chat/providers/active_chat_state.dart';
import 'package:genie/features/chat/providers/chat_participant_providers.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/shared/utils/owner_display_name.dart';

/// App-bar title of a conversation: who it is with and whether they are
/// online. Tapping it opens the participant sheet: their profile (with a way
/// to their full profile page) and the security code, as two tabs.
class ChatConversationHeader extends ConsumerWidget {
  final String participantName;

  /// Null until it is known who is signed in; then only the name is shown.
  final ChatParticipants? chat;

  const ChatConversationHeader({
    super.key,
    required this.participantName,
    required this.chat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chat = this.chat;
    final avatarUrl = chat == null
        ? null
        : ref
              .watch(chatParticipantProfileProvider(chat.participantId))
              .valueOrNull
              ?.avatarUrl;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: chat == null
          ? null
          : () => showChatParticipantSheet(
              context,
              chat: chat,
              participantName: participantName,
            ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserAvatar(name: participantName, avatarUrl: avatarUrl, radius: 18),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ownerDisplayName(context.l10n, participantName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: context.colors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (chat != null)
                    ChatPresenceLabel(userId: chat.participantId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
