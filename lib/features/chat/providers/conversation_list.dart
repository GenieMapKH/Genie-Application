import 'package:tilomnov/features/chat/models/chat_models.dart';
import 'package:tilomnov/shared/utils/paged_list.dart';

/// A conversation list as shown: the conversations loaded so far, and the
/// unread messages in the whole list, loaded or not (the chat tab's badge).
class ConversationList {
  final PagedList<ChatConversation> page;
  final int unreadTotal;

  const ConversationList({this.page = const PagedList(), this.unreadTotal = 0});

  List<ChatConversation> get items => page.items;

  /// The same totals with [items] shown instead, the unread total moved by
  /// [unreadChange].
  ConversationList withItems(
    List<ChatConversation> items, {
    int unreadChange = 0,
  }) {
    return ConversationList(
      page: page.copyWith(items: items),
      unreadTotal: (unreadTotal + unreadChange).clamp(0, 1 << 31),
    );
  }

  ConversationList withLoadingMore(bool loadingMore) => ConversationList(
    page: page.copyWith(loadingMore: loadingMore),
    unreadTotal: unreadTotal,
  );
}
