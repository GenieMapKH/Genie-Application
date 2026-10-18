import 'package:flutter/material.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/chat/models/chat_models.dart';
import 'package:genie/features/chat/presentation/widgets/conversation_list/chat_list_entry.dart';

/// The conversations of the chat list or the archive, one row each.
class ChatConversationListView extends StatelessWidget {
  final List<ChatConversation> conversations;
  final bool isArchived;

  const ChatConversationListView({
    super.key,
    required this.conversations,
    required this.isArchived,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: conversations.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 1,
        color: context.colors.divider,
        indent: 16,
        endIndent: 16,
      ),
      itemBuilder: (context, index) => ChatListEntry(
        key: ValueKey(conversations[index].participantId),
        chat: conversations[index],
        isArchived: isArchived,
      ),
    );
  }
}
