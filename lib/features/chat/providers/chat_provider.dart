import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/chat/data/chat_repository.dart';
import 'package:genie/features/chat/data/chat_socket_service.dart';
import 'package:genie/features/chat/e2ee/message_cipher.dart';
import 'package:genie/features/chat/models/chat_models.dart';
import 'package:genie/features/chat/providers/chat_service_providers.dart';
import 'package:genie/features/profile/presentation/view_models/user_providers.dart';

/// The signed-in user's conversation list, kept current by the chat socket.
class ConversationsNotifier
    extends StateNotifier<AsyncValue<List<ChatConversation>>> {
  final ChatRepository repository;
  final ChatSocketService socketService;

  /// Decrypts the last-message previews. Null for a guest, who has no chats.
  final MessageCipher? cipher;

  final _subscriptions = <StreamSubscription<void>>[];
  bool _refreshing = false;
  bool _refreshAgain = false;

  /// [signInPending] keeps the list loading while it is not yet known who,
  /// if anyone, is signed in.
  ConversationsNotifier({
    required this.repository,
    required this.socketService,
    required this.cipher,
    bool signInPending = false,
  }) : super(const AsyncValue.loading()) {
    if (cipher == null) {
      if (!signInPending) state = const AsyncValue.data([]);
      return;
    }
    _subscriptions
      ..add(socketService.onMessage.listen(_onMessage))
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

  /// Replaces the "encrypted" placeholder of [conversation]'s last message
  /// with its text, unless a newer message arrived meanwhile.
  Future<void> _showPreview(ChatConversation conversation) async {
    final withPreview = await _withPreview(conversation);
    final conversations = state.valueOrNull;
    if (!mounted || conversations == null) return;
    state = AsyncValue.data([
      for (final current in conversations)
        current.participantId == conversation.participantId &&
                current.lastMessageId == conversation.lastMessageId
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
      final conversations = await repository.fetchConversations();
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

    final opened = await cipher!.decrypt(lastMessage);
    if (opened == null) return conversation;
    return conversation.copyWith(
      lastMessage: opened.text.isEmpty && opened.attachment != null
          ? ChatConversation.photoPreview
          : opened.text,
    );
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

final unreadCountProvider = Provider<int>((ref) {
  final convsState = ref.watch(conversationsProvider);
  return convsState.maybeWhen(
    data: (conversations) =>
        conversations.fold(0, (sum, item) => sum + item.unreadCount),
    orElse: () => 0,
  );
});
