import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/chat/data/chat_repository.dart';
import 'package:genie/features/chat/data/chat_socket_service.dart';
import 'package:genie/features/chat/e2ee/keys/message_cipher.dart';
import 'package:genie/features/chat/models/chat_models.dart';
import 'package:genie/features/chat/providers/chat_service_providers.dart';
import 'package:genie/features/profile/presentation/view_models/user_providers.dart';

/// The signed-in user's conversation list (or, with [archived], the
/// archive), kept current by the chat socket.
class ConversationsNotifier
    extends StateNotifier<AsyncValue<List<ChatConversation>>> {
  final ChatRepository repository;
  final ChatSocketService socketService;

  /// Lists the archive instead of the main list.
  final bool archived;

  /// Decrypts the last-message previews. Null for a guest, who has no chats.
  final MessageCipher? cipher;

  final _subscriptions = <StreamSubscription<void>>[];
  bool _refreshing = false;
  bool _refreshAgain = false;

  /// Previews already decrypted, by message id and nonce (an edit is sealed
  /// with a new nonce), so reloading the list opens only what is new.
  final _previews = <String, String>{};
  static const _maxPreviews = 500;

  /// [signInPending] keeps the list loading while it is not yet known who,
  /// if anyone, is signed in.
  ConversationsNotifier({
    required this.repository,
    required this.socketService,
    required this.cipher,
    this.archived = false,
    bool signInPending = false,
  }) : super(const AsyncValue.loading()) {
    if (cipher == null) {
      if (!signInPending) state = const AsyncValue.data([]);
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
  /// the whole list again. The unread count changes at once; the preview
  /// follows when it has been decrypted. A message from someone not in the
  /// list yet needs their name and picture, so the list is loaded again.
  void _onMessage(EncryptedMessage message) {
    final conversations = state.valueOrNull;
    if (conversations == null) return;

    final peerId = message.peerOf(cipher!.userId);
    // A new message takes a conversation out of the archive.
    if (archived) {
      removeLocally(peerId);
      return;
    }
    final index = conversations.indexWhere((c) => c.participantId == peerId);
    if (index < 0) {
      refresh();
      return;
    }

    final updated = conversations[index].withNewMessage(message);
    state = AsyncValue.data([
      updated,
      for (final (i, conversation) in conversations.indexed)
        if (i != index) conversation,
    ]);
    unawaited(_showPreview(updated));
  }

  /// The user sent [message], reading [preview], from this device: its
  /// conversation moves to the top with it, without loading the list again.
  /// One not on this list yet (a first message, or one archived until now)
  /// needs the server's answer.
  void recordSent(EncryptedMessage message, {required String preview}) {
    final conversations = state.valueOrNull;
    if (cipher == null || archived || conversations == null) return;

    final peerId = message.peerOf(cipher!.userId);
    final index = conversations.indexWhere((c) => c.participantId == peerId);
    if (index < 0) {
      refresh();
      return;
    }
    _remember(message.id, message.nonce, preview);
    state = AsyncValue.data([
      conversations[index]
          .withNewMessage(message)
          .copyWith(lastMessage: preview),
      for (final (i, conversation) in conversations.indexed)
        if (i != index) conversation,
    ]);
  }

  /// A message was edited, on any device: only the list's preview of it
  /// can change.
  void _onMessageEdited(EncryptedMessage message) {
    final conversations = state.valueOrNull;
    if (conversations == null) return;
    final peerId = message.peerOf(cipher!.userId);
    final current = conversations
        .where(
          (c) => c.participantId == peerId && c.lastMessageId == message.id,
        )
        .firstOrNull;
    if (current == null) return;

    final edited = current.withEditedLastMessage(message);
    state = AsyncValue.data([
      for (final conversation in conversations)
        identical(conversation, current) ? edited : conversation,
    ]);
    unawaited(_showPreview(edited));
  }

  /// A message was deleted, on any device. Only the server knows what comes
  /// before a deleted last message, and how many unread messages are left.
  void _onMessageDeleted(String participantId, String messageId) {
    final conversations = state.valueOrNull;
    if (conversations == null) return;
    final conversation = conversations
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
    final withPreview = await _withPreview(conversation);
    final conversations = state.valueOrNull;
    if (!mounted || conversations == null) return;
    state = AsyncValue.data([
      for (final current in conversations)
        current.participantId == conversation.participantId &&
                current.lastMessageId == conversation.lastMessageId &&
                current.lastNonce == conversation.lastNonce
            ? current.copyWith(lastMessage: withPreview.lastMessage)
            : current,
    ]);
  }

  /// Reloads the list. Calls made while a reload is running are merged into
  /// one follow-up reload, so a burst of messages costs one request.
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
    try {
      final conversations = await repository.fetchConversations(
        archived: archived,
      );
      final withPreviews = await Future.wait(conversations.map(_withPreview));
      if (mounted) state = AsyncValue.data(withPreviews);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load conversations', e, stackTrace);
      // A failed reload keeps the list already on screen.
      if (mounted && !state.hasValue) state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<ChatConversation> _withPreview(ChatConversation conversation) async {
    final lastMessage = conversation.lastMessageFor(cipher!.userId);
    if (lastMessage == null) return conversation;

    final known = _previews[_previewKey(lastMessage.id, lastMessage.nonce)];
    if (known != null) return conversation.copyWith(lastMessage: known);

    final opened = await cipher!.decrypt(lastMessage);
    if (opened == null) return conversation;
    final preview = ChatConversation.previewOf(opened.text, opened.attachment);
    _remember(lastMessage.id, lastMessage.nonce, preview);
    return conversation.copyWith(lastMessage: preview);
  }

  static String _previewKey(String messageId, String nonce) =>
      '$messageId:$nonce';

  /// Only what decrypted is kept: a failure may succeed later.
  void _remember(String messageId, String nonce, String preview) {
    final key = _previewKey(messageId, nonce);
    _previews.remove(key);
    _previews[key] = preview;
    if (_previews.length > _maxPreviews) _previews.remove(_previews.keys.first);
  }

  /// Takes [participantId]'s conversation off this list at once, before the
  /// server confirms an archive or delete; [refresh] puts it back if needed.
  void removeLocally(String participantId) {
    final conversations = state.valueOrNull;
    if (!mounted || conversations == null) return;
    state = AsyncValue.data([
      for (final conversation in conversations)
        if (conversation.participantId != participantId) conversation,
    ]);
  }

  /// Clears the unread count at once, then tells the server. Cleared first,
  /// so a message counted as it arrived in an open chat never stays unread.
  Future<void> markAsRead(String participantId) async {
    if (mounted && state.hasValue) {
      state = AsyncValue.data([
        for (final conversation in state.value!)
          conversation.participantId == participantId
              ? conversation.copyWith(unreadCount: 0)
              : conversation,
      ]);
    }
    try {
      await repository.markAsRead(participantId);
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
    StateNotifierProvider<
      ConversationsNotifier,
      AsyncValue<List<ChatConversation>>
    >((ref) {
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
      AsyncValue<List<ChatConversation>>
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

/// Unread messages in the main list. Archived conversations hold none that
/// matter: a new message takes a conversation out of the archive.
final unreadCountProvider = Provider<int>((ref) {
  final convsState = ref.watch(conversationsProvider);
  return convsState.maybeWhen(
    data: (conversations) =>
        conversations.fold(0, (sum, item) => sum + item.unreadCount),
    orElse: () => 0,
  );
});
