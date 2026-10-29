import 'package:flutter/material.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/chat/models/chat_models.dart';
import 'package:tilomnov/features/chat/presentation/widgets/conversation_list/chat_list_entry.dart';
import 'package:tilomnov/shared/utils/paged_list.dart';
import 'package:tilomnov/shared/widgets/lists/load_more_on_scroll.dart';
import 'package:tilomnov/shared/widgets/lists/loading_more_indicator.dart';

/// The conversations of the chat list or the archive, one row each; the
/// next page is asked for with [onLoadMore] as the end comes near.
class ChatConversationListView extends StatelessWidget {
  final PagedList<ChatConversation> page;
  final bool isArchived;
  final VoidCallback onLoadMore;

  const ChatConversationListView({
    super.key,
    required this.page,
    required this.isArchived,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    final conversations = page.items;
    return LoadMoreOnScroll(
      enabled: page.hasMore && !page.loadingMore,
      onLoadMore: onLoadMore,
      child: ListView.separated(
        itemCount: conversations.length + (page.loadingMore ? 1 : 0),
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 1,
          color: context.colors.divider,
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          if (index == conversations.length) {
            return const LoadingMoreIndicator();
          }
          return ChatListEntry(
            key: ValueKey(conversations[index].participantId),
            chat: conversations[index],
            isArchived: isArchived,
          );
        },
      ),
    );
  }
}
