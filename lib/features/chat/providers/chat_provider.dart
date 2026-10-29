import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/features/chat/data/chat_repository.dart';
import 'package:tilomnov/features/chat/data/chat_socket_service.dart';
import 'package:tilomnov/features/chat/e2ee/keys/message_cipher.dart';
import 'package:tilomnov/features/chat/models/chat_models.dart';
import 'package:tilomnov/features/chat/providers/chat_service_providers.dart';
import 'package:tilomnov/features/chat/providers/conversation_list.dart';
import 'package:tilomnov/features/chat/providers/conversation_previews.dart';
import 'package:tilomnov/features/profile/presentation/view_models/user_providers.dart';
import 'package:tilomnov/shared/utils/paged_list.dart';

/// The signed-in user's conversation list (or, with [archived], the
/// archive), a page at a time, kept current by the chat socket.
class ConversationsNotifier
    extends StateNotifier<AsyncValue<ConversationList>> {
  final ChatRepository repository;
  final ChatSocketService socketService;

  /// Lists the archive instead of the main list.
  final bool archived;

  /// Decrypts the last-message previews. Null for a guest, who has no chats.
  final MessageCipher? cipher;

  final ConversationPreviews? _previews;
  final _subscriptions = <StreamSubscription<void>>[];
  bool _refreshing = false;
  bool _refreshAgain = false;

  /// Where the next page starts; null after the last.
  String? _nextCursor;

  /// Counts reloads, so a page that was on its way during one is dropped.
  int _generation = 0;

  /// [signInPending] keeps the list loading while it is not yet known who,
  /// if anyone, is signed in.
  ConversationsNotifier({
    required this.repository,
    required this.socketService,
    required this.cipher,
    this.archived = false,
    bool signInPending = false,
  }) : _previews = cipher == null ? null : ConversationPreviews(cipher),
       super(const AsyncValue.loading()) {
    if (cipher == null) {
      if (!signInPending) state = const AsyncValue.data(ConversationList());
      return;
    }
    _subscriptions
      ..add(socketService.onMessage.listen(_onMessage))
      // Archived or deleted on another device, or deleted by the other person.
      ..add(socketService.onConversationChanged.listen((_) => refresh()))
      // The last message may have new text, or be gone.
      ..add(socketService.onMessageEdited.listen(_onMessageEdited))
      ..add(
        socketService.onMessageDeleted.listen(
          (deletion) =>
              _onMessageDeleted(deletion.participantId, deletion.messageId),
        ),
      )
      // Messages may have been missed while disconnected.
      ..add(socketService.onConnected.listen((_) => refresh()));
    refresh();
  }

  /// Updates the one conversation [message] belongs to, instead of loading
  /// the whole list again. The unread counts change at once; the preview
  /// follows when it has been decrypted. A message from someone not in the
  /// list yet (or not loaded yet) needs their name and picture, so the list
  /// is loaded again.
  void _onMessage(EncryptedMessage message) {
    final list = state.valueOrNull;
    if (list == null) return;

    final peerId = message.peerOf(cipher!.userId);
    // A new message takes a conversation out of the archive.
    if (archived) {
      removeLocally(peerId);
      return;
    }
    final index = list.items.indexWhere((c) => c.participantId == peerId);
    if (index < 0) {
      refresh();
      return;
    }

    final before = list.items[index];
    final updated = before.withNewMessage(message);
    state = AsyncValue.data(
      list.withItems(
        _onTop(updated, list.items, index),
        unreadChange: updated.unreadCount - before.unreadCount,
      ),
    );
    unawaited(_showPreview(updated));
  }

  /// [conversations] with [moved], once at [index], first.
  static List<ChatConversation> _onTop(
    ChatConversation moved,
    List<ChatConversation> conversations,
    int index,
  ) => [
    moved,
    for (final (i, conversation) in conversations.indexed)
      if (i != index) conversation,
  ];

  /// The user sent [message], reading [preview], from this device: its
  /// conversation moves to the top with it, without loading the list again.
  /// One not on this list yet (a first message, or one archived until now)
  /// needs the server's answer.
  void recordSent(EncryptedMessage message, {required String preview}) {
    final list = state.valueOrNull;
    if (cipher == null || archived || list == null) return;

    final peerId = message.peerOf(cipher!.userId);
    final index = list.items.indexWhere((c) => c.participantId == peerId);
    if (index < 0) {
      refresh();
      return;
    }
    _previews!.remember(message.id, message.nonce, preview);
    final sent = list.items[index]
        .withNewMessage(message)
        .copyWith(lastMessage: preview);
    state = AsyncValue.data(list.withItems(_onTop(sent, list.items, index)));
  }

  /// A message was edited, on any device: only the list's preview of it
  /// can change.
  void _onMessageEdited(EncryptedMessage message) {
    final list = state.valueOrNull;
    if (list == null) return;
    final peerId = message.peerOf(cipher!.userId);
    final current = list.items
        .where(
          (c) => c.participantId == peerId && c.lastMessageId == message.id,
        )
        .firstOrNull;
    if (current == null) return;

    final edited = current.withEditedLastMessage(message);
    state = AsyncValue.data(
      list.withItems([
        for (final conversation in list.items)
          identical(conversation, current) ? edited : conversation,
      ]),
    );
    unawaited(_showPreview(edited));
  }

  /// A message was deleted, on any device. Only the server knows what comes
  /// before a deleted last message, and how many unread messages are left.
  void _onMessageDeleted(String participantId, String messageId) {
    final list = state.valueOrNull;
    if (list == null) return;
    final conversation = list.items
        .where((c) => c.participantId == participantId)
        .firstOrNull;
    if (conversation == null ||
        conversation.lastMessageId == messageId ||
        conversation.unreadCount > 0) {
      refresh();
    }
  }

  /// Replaces the "encrypted" placeholder of [conversation]'s last message
  /// with its text, unless a newer message (or edit) arrived meanwhile.
  Future<void> _showPreview(ChatConversation conversation) async {
    final withPreview = await _previews!.shown(conversation);
    final list = state.valueOrNull;
    if (!mounted || list == null) return;
    state = AsyncValue.data(
      list.withItems([
        for (final current in list.items)
          current.participantId == conversation.participantId &&
                  current.lastMessageId == conversation.lastMessageId &&
                  current.lastNonce == conversation.lastNonce
              ? current.copyWith(lastMessage: withPreview.lastMessage)
              : current,
      ]),
    );
  }

  /// Reloads as many conversations as are shown (at least a page, at most
  /// the server's limit). Calls made while a reload is running are merged
  /// into one follow-up reload, so a burst of messages costs one request.
  Future<void> refresh() async {
    if (cipher == null) return;
    if (_refreshing) {
      _refreshAgain = true;
      return;
    }

    _refreshing = true;
    try {
      do {
        _refreshAgain = false;
        await _load();
      } while (_refreshAgain && mounted);
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final shown = state.valueOrNull?.items.length ?? 0;
    try {
      final page = await repository.fetchConversationPage(
        archived: archived,
        limit: shown.clamp(
          ChatRepository.conversationPageSize,
          ChatRepository.maxConversationPage,
        ),
      );
      final items = await Future.wait(page.items.map(_previews!.shown));
      if (!mounted || generation != _generation) return;
      _nextCursor = page.nextCursor;
      state = AsyncValue.data(
        ConversationList(
          page: PagedList(items: items, hasMore: page.nextCursor != null),
          unreadTotal: page.unreadTotal,
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load conversations', e, stackTrace);
      // A failed reload keeps the list already on screen.
      if (mounted && !state.hasValue) state = AsyncValue.error(e, stackTrace);
    }
  }

  /// The next page, added after the conversations already shown.
  Future<void> loadMore() async {
    final list = state.valueOrNull;
    final cursor = _nextCursor;
    if (list == null || cursor == null || list.page.loadingMore) return;

    final generation = _generation;
    state = AsyncValue.data(list.withLoadingMore(true));
    try {
      final page = await repository.fetchConversationPage(
        archived: archived,
        cursor: cursor,
      );
      final items = await Future.wait(page.items.map(_previews!.shown));
      if (!mounted || generation != _generation) return;
      _nextCursor = page.nextCursor;
      // Messages may have arrived meanwhile: added to what is shown now.
      final current = state.valueOrNull ?? list;
      state = AsyncValue.data(
        ConversationList(
          page: current.page.appended(
            items,
            hasMore: page.nextCursor != null,
            idOf: (c) => c.participantId,
          ),
          unreadTotal: page.unreadTotal,
        ),
      );
    } catch (e) {
      AppLogger.error('Loading more conversations failed', e);
      final current = state.valueOrNull;
      if (mounted && generation == _generation && current != null) {
        state = AsyncValue.data(current.withLoadingMore(false));
      }
    }
  }

  /// Takes [participantId]'s conversation off this list at once, before the
  /// server confirms an archive or delete; [refresh] puts it back if needed.
  void removeLocally(String participantId) {
    final list = state.valueOrNull;
    if (!mounted || list == null) return;
    bool isRemoved(ChatConversation c) => c.participantId == participantId;
    state = AsyncValue.data(
      list.withItems(
        list.items.where((c) => !isRemoved(c)).toList(),
        unreadChange: -list.items
            .where(isRemoved)
            .fold(0, (sum, c) => sum + c.unreadCount),
      ),
    );
  }

  /// Clears the unread count at once, then tells the server. Cleared first,
  /// so a message counted as it arrived in an open chat never stays unread.
  /// For a conversation not loaded, only the server knows how many were
  /// unread, so the list is read again once it has been told.
  Future<void> markAsRead(String participantId) async {
    final list = state.valueOrNull;
    final read = list?.items
        .where((c) => c.participantId == participantId)
        .firstOrNull;
    if (mounted && list != null && read != null) {
      state = AsyncValue.data(
        list.withItems([
          for (final conversation in list.items)
            identical(conversation, read)
                ? conversation.copyWith(unreadCount: 0)
                : conversation,
        ], unreadChange: -read.unreadCount),
      );
    }
    try {
      await repository.markAsRead(participantId);
      if (read == null && (list?.unreadTotal ?? 0) > 0) await refresh();
    } catch (e) {
      // The server still counts them; the next full reload shows that.
      AppLogger.error('Failed to mark messages as read', e);
    }
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}

final conversationsProvider =
    StateNotifierProvider<ConversationsNotifier, AsyncValue<ConversationList>>((
      ref,
    ) {
      final userId = ref.watch(currentUserIdProvider);
      return ConversationsNotifier(
        repository: ref.watch(chatRepositoryProvider),
        socketService: ref.watch(chatSocketServiceProvider),
        cipher: userId == null
            ? null
            : ref.watch(messageCipherProvider(userId)),
        signInPending:
            userId == null &&
            ref.watch(userProfileProvider.select((p) => p.isLoading)),
      );
    });

/// Archived conversations, for the archive page.
final archivedConversationsProvider =
    StateNotifierProvider.autoDispose<
      ConversationsNotifier,
      AsyncValue<ConversationList>
    >((ref) {
      final userId = ref.watch(currentUserIdProvider);
      return ConversationsNotifier(
        repository: ref.watch(chatRepositoryProvider),
        socketService: ref.watch(chatSocketServiceProvider),
        cipher: userId == null
            ? null
            : ref.watch(messageCipherProvider(userId)),
        archived: true,
      );
    });

/// Unread messages in the main list, loaded or not, as the server counts
/// them and kept current here. Archived conversations hold none that
/// matter: a new message takes a conversation out of the archive.
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(
    conversationsProvider.select((list) => list.valueOrNull?.unreadTotal ?? 0),
  );
});
