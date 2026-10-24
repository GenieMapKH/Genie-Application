import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/chat/data/chat_attachment_service.dart';
import 'package:genie/features/chat/data/chat_message_changes.dart';
import 'package:genie/features/chat/data/chat_repository.dart';
import 'package:genie/features/chat/data/chat_socket_service.dart';
import 'package:genie/features/chat/e2ee/e2ee_setup_service.dart';
import 'package:genie/features/chat/e2ee/keys/message_cipher.dart';
import 'package:genie/features/chat/e2ee/message_reader.dart';
import 'package:genie/features/chat/e2ee/backup/pin_check.dart';
import 'package:genie/features/chat/models/chat_message_action_problem.dart';
import 'package:genie/features/chat/models/chat_message_list.dart';
import 'package:genie/features/chat/models/chat_models.dart';
import 'package:genie/features/chat/models/chat_send_problem.dart';
import 'package:genie/features/chat/models/chat_voice.dart';
import 'package:genie/features/chat/models/conversation_change.dart';
import 'package:genie/features/chat/models/message_deletion.dart';
import 'package:genie/features/chat/providers/active_chat_state.dart';
import 'package:genie/features/chat/providers/chat_provider.dart';
import 'package:genie/features/chat/providers/chat_service_providers.dart';
import 'package:genie/shared/utils/random_uuid.dart';
import 'package:genie/features/chat/models/chat_listing.dart';

export 'active_chat_state.dart';

/// Loads, receives and sends the messages of one conversation.
class ActiveChatNotifier extends StateNotifier<ActiveChatState> {
  static const undecryptableText = ChatMessage.undecryptableText;

  /// An unreadable live message triggers a key check at most this often.
  static const _keyCheckCooldown = Duration(seconds: 30);

  final String userId;
  final String participantId;
  final ChatRepository repository;
  final ChatSocketService socketService;
  final E2eeSetupService setupService;
  final MessageCipher cipher;
  final ChatAttachmentService attachments;
  final ConversationsNotifier conversations;
  final ChatMessageReader _reader;
  final ChatMessageChanges _changes;

  /// Files (pictures, voice messages) still being sent, by message id.
  final _outgoingFiles = <String, _OutgoingFile>{};

  final _subscriptions = <StreamSubscription<void>>[];

  /// Set once this device holds the keys, so messages can be decrypted.
  bool _keysReady = false;
  DateTime? _lastKeyCheck;

  /// Live messages are handled one at a time so they stay in arrival order.
  Future<void> _incoming = Future.value();

  ActiveChatNotifier({
    required this.userId,
    required this.participantId,
    required this.repository,
    required this.socketService,
    required this.setupService,
    required this.cipher,
    required this.attachments,
    required this.conversations,
  }) : _reader = ChatMessageReader(cipher),
       _changes = ChatMessageChanges(cipher: cipher, repository: repository),
       super(const ActiveChatState()) {
    _subscriptions
      ..add(socketService.onMessage.listen(_queueIncoming))
      ..add(socketService.onMessageEdited.listen(_queueEdit))
      ..add(socketService.onMessageDeleted.listen(_onMessageDeleted))
      ..add(socketService.onConnected.listen((_) => _reloadAfterReconnect()))
      ..add(socketService.onConversationChanged.listen(_onConversationChanged));
  }

  /// Makes encryption ready, then loads the conversation. [askPin] is used
  /// only on a device without the account's keys: they come back with the
  /// chat PIN.
  Future<void> open({required PinPrompt askPin}) async {
    _keysReady = false;
    state = const ActiveChatState();
    try {
      final result = await setupService.initialize(userId, askPin: askPin);
      if (!mounted) return;
      if (result != E2eeSetupResult.ready) {
        state = ActiveChatState(
          status: ActiveChatStatus.unavailable,
          setupResult: result,
        );
        return;
      }

      // From here on live messages are kept, and merged with the history.
      _keysReady = true;
      final keyStatus = await _checkPeerKey();
      final history = await _fetchHistory();
      if (!mounted) return;
      state = state.copyWith(
        status: ActiveChatStatus.ready,
        messages: _mergeHistory(history),
        peerKeyChanged: keyStatus == PeerKeyStatus.changed,
      );
      unawaited(conversations.markAsRead(participantId));
      // Previews could not be decrypted before the keys were on this device.
      unawaited(conversations.refresh());
    } catch (e, stackTrace) {
      AppLogger.error('Failed to open chat', e, stackTrace);
      if (!mounted) return;
      _keysReady = false;
      state = const ActiveChatState(
        status: ActiveChatStatus.unavailable,
        setupResult: E2eeSetupResult.failed,
      );
    }
  }

  /// Sends [text], as a reply to [replyTo] when given.
  Future<void> sendMessage(String text, {ChatMessage? replyTo}) async {
    if (state.status != ActiveChatStatus.ready || state.peerKeyChanged) return;

    final message = ChatMessage(
      id: _newMessageId(),
      senderId: userId,
      recipientId: participantId,
      text: text,
      createdAt: DateTime.now(),
      status: ChatMessageStatus.sending,
      replyToId: replyTo?.id,
      replyTo: replyTo?.asReplyPreview,
    );
    state = state.copyWith(messages: [...state.messages, message]);
    await _deliver(message);
  }

  /// Sends [listing] as a card. Its text says what it is, for an app that
  /// cannot draw the card and for the notification.
  Future<void> sendListing(ChatListing listing) async {
    if (state.status != ActiveChatStatus.ready || state.peerKeyChanged) return;

    final message = ChatMessage(
      id: _newMessageId(),
      senderId: userId,
      recipientId: participantId,
      text: listing.fallbackText,
      createdAt: DateTime.now(),
      status: ChatMessageStatus.sending,
      listing: listing,
    );
    state = state.copyWith(messages: [...state.messages, message]);
    await _deliver(message);
  }

  /// Sends a picture. It is shown at once, then encrypted, uploaded and
  /// announced to the other person in an ordinary encrypted message.
  Future<void> sendImage(
    Uint8List bytes, {
    required String name,
    required String mimeType,
  }) async {
    await _sendFile((
      bytes: bytes,
      name: name,
      mimeType: mimeType,
      voice: null,
    ), localImage: bytes);
  }

  /// Sends a voice message recorded on this device, the same way as a
  /// picture: shown at once, then encrypted, uploaded and announced.
  Future<void> sendVoice(RecordedVoiceNote note) async {
    await _sendFile((
      bytes: note.bytes,
      name: note.fileName,
      mimeType: note.mimeType,
      voice: note.details,
    ), localVoice: note);
  }

  /// Shows a message carrying [file] at once (as its local copy), then
  /// uploads the file and sends the message.
  Future<void> _sendFile(
    _OutgoingFile file, {
    Uint8List? localImage,
    RecordedVoiceNote? localVoice,
  }) async {
    if (state.status != ActiveChatStatus.ready || state.peerKeyChanged) return;

    final message = ChatMessage(
      id: _newMessageId(),
      senderId: userId,
      recipientId: participantId,
      text: '',
      createdAt: DateTime.now(),
      status: ChatMessageStatus.sending,
      localImage: localImage,
      localVoice: localVoice,
    );
    _outgoingFiles[message.id] = file;
    state = state.copyWith(messages: [...state.messages, message]);
    await _deliver(message);
  }

  /// Sends a failed message again. It keeps its id, so the server stores it
  /// once even if the first attempt did arrive.
  Future<void> retry(String messageId) async {
    final failed = state.messages
        .where((m) => m.id == messageId && m.status == ChatMessageStatus.failed)
        .firstOrNull;
    if (failed == null || state.peerKeyChanged) return;

    final message = failed.copyWith(status: ChatMessageStatus.sending);
    _replace(message);
    await _deliver(message);
  }

  /// The user agrees to use the other person's new key. Messages sealed
  /// with their old key can no longer be read.
  Future<void> acceptNewPeerKey() async {
    try {
      await cipher.trustCurrentPeerKey(participantId);
      final history = await _fetchHistory();
      if (!mounted) return;
      state = state.copyWith(
        messages: _mergeHistory(history),
        peerKeyChanged: false,
      );
      unawaited(conversations.refresh());
    } catch (e, stackTrace) {
      AppLogger.error('Failed to accept the new key', e, stackTrace);
      if (!mounted) return;
      state = state.copyWith(sendError: ChatSendProblem.noConnection);
    }
  }

  Future<void> _deliver(ChatMessage message) async {
    try {
      message = await _uploadPendingFile(message);
      final sealed = await cipher.encrypt(
        message.text,
        id: message.id,
        peerId: participantId,
        attachment: message.attachment,
        replyToId: message.replyToId,
        listing: message.listing,
      );
      await socketService.send(
        id: message.id,
        recipientId: participantId,
        ciphertext: sealed.ciphertext,
        nonce: sealed.nonce,
        replyToId: message.replyToId,
      );
      if (!mounted) return;
      _outgoingFiles.remove(message.id);
      _replace(message.copyWith(status: ChatMessageStatus.sent));
      _showInConversationList(message, sealed);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to send message', e, stackTrace);
      if (!mounted) return;
      _replace(
        message.copyWith(status: ChatMessageStatus.failed),
        peerKeyChanged: e is PeerKeyChangedException ? true : null,
        sendError: switch (e) {
          ChatSendException(:final problem) => problem,
          ChatEncryptionException(:final problem) => problem,
          _ => ChatSendProblem.failed,
        },
      );
    }
  }

  /// Makes the message just sent the conversation's last one in the list,
  /// unless a newer one is already stored there (sent or received since).
  void _showInConversationList(
    ChatMessage message,
    ({String ciphertext, String nonce}) sealed,
  ) {
    final newestStored = state.messages.lastWhere(
      (m) => m.status == ChatMessageStatus.sent,
      orElse: () => message,
    );
    if (newestStored.id != message.id) return;
    conversations.recordSent(
      EncryptedMessage(
        id: message.id,
        senderId: userId,
        recipientId: participantId,
        ciphertext: sealed.ciphertext,
        nonce: sealed.nonce,
        createdAt: message.createdAt,
      ),
      preview: ChatConversation.previewOf(message.text, message.attachment),
    );
  }

  /// Replaces the text of the user's own message, sealed again for the
  /// other person. Null when done, otherwise why not. The conversation list
  /// follows the server's `messageEdited` event, which every device of the
  /// user receives.
  Future<ChatMessageActionProblem?> editMessage(
    String messageId,
    String text,
  ) async {
    final message = _find(messageId);
    if (message == null || !message.canBeEditedBy(userId, DateTime.now())) {
      return ChatMessageActionProblem.editTooLate;
    }
    if (text == message.text) return null;

    final result = await _changes.edit(message, text, peerId: participantId);
    final editedAt = result.editedAt;
    if (!mounted || editedAt == null) return result.problem;
    state = state.copyWith(
      messages: state.messages.withEdit(message.id, text, editedAt),
    );
    return null;
  }

  /// Deletes a message for this user, or with [forEveryone] (their own
  /// message) for both people. Nothing is left in its place. A message that
  /// was never sent is only taken off this screen. The conversation list
  /// follows the server's `messageDeleted` event, as for an edit.
  Future<ChatMessageActionProblem?> deleteMessage(
    String messageId, {
    required bool forEveryone,
  }) async {
    final message = _find(messageId);
    if (message == null || message.status == ChatMessageStatus.sending) {
      return null;
    }
    if (message.status == ChatMessageStatus.failed) {
      _outgoingFiles.remove(messageId);
      state = state.copyWith(messages: state.messages.without(messageId));
      return null;
    }

    final problem = await _changes.delete(
      message,
      forEveryone: forEveryone && message.senderId == userId,
    );
    if (problem != null || !mounted) return problem;
    state = state.copyWith(messages: state.messages.without(messageId));
    return null;
  }

  /// Uploads the file of a message that has one and is not stored yet.
  /// A retry after a later failure does not upload it a second time.
  Future<ChatMessage> _uploadPendingFile(ChatMessage message) async {
    final file = _outgoingFiles[message.id];
    if (message.attachment != null || file == null) return message;

    final attachment = await attachments.send(
      file.bytes,
      recipientId: participantId,
      name: file.name,
      mimeType: file.mimeType,
      voice: file.voice,
    );
    final uploaded = message.copyWith(attachment: attachment);
    if (mounted) _replace(uploaded);
    return uploaded;
  }

  void _queueIncoming(EncryptedMessage encrypted) {
    _incoming = _incoming.then((_) => _receive(encrypted));
  }

  Future<void> _receive(EncryptedMessage encrypted) async {
    if (!_keysReady || encrypted.peerOf(userId) != participantId) return;
    try {
      final message = await _reader.read(encrypted);
      if (!mounted || !_keysReady) return;

      final known = state.messages.any((m) => m.id == message.id);
      if (known) {
        _replace(message, sendError: state.sendError);
      } else {
        state = state.copyWith(
          messages: [...state.messages, message],
          sendError: state.sendError,
        );
      }
      if (message.senderId == participantId) {
        unawaited(conversations.markAsRead(participantId));
      }
      // Unreadable may mean the other person now uses a different key.
      if (!message.isReadable) await _recheckPeerKeyAfterUnreadable();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to show an incoming message', e, stackTrace);
    }
  }

  /// Edits are handled in turn with new messages, so an edit never comes
  /// before the message it changes.
  void _queueEdit(EncryptedMessage encrypted) {
    _incoming = _incoming.then((_) => _receiveEdit(encrypted));
  }

  Future<void> _receiveEdit(EncryptedMessage encrypted) async {
    if (!_keysReady || encrypted.peerOf(userId) != participantId) return;
    try {
      final edited = await _reader.read(encrypted);
      if (!mounted || _find(edited.id) == null) return;
      state = state.copyWith(
        messages: state.messages.withEdit(
          edited.id,
          edited.text,
          edited.editedAt ?? DateTime.now(),
        ),
        sendError: state.sendError,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to show an edited message', e, stackTrace);
    }
  }

  void _onMessageDeleted(MessageDeletion deletion) {
    if (deletion.participantId != participantId) return;
    state = state.copyWith(
      messages: state.messages.without(deletion.messageId),
      sendError: state.sendError,
    );
  }

  Future<void> _recheckPeerKeyAfterUnreadable() async {
    final last = _lastKeyCheck;
    if (last != null && DateTime.now().difference(last) < _keyCheckCooldown) {
      return;
    }
    final status = await _checkPeerKey();
    if (mounted && status == PeerKeyStatus.changed && !state.peerKeyChanged) {
      state = state.copyWith(peerKeyChanged: true, sendError: state.sendError);
    }
  }

  Future<PeerKeyStatus> _checkPeerKey() {
    _lastKeyCheck = DateTime.now();
    return cipher.checkPeerKey(participantId);
  }

  /// The conversation was deleted (by the other person, for everyone, or on
  /// another device): show only what the server still has.
  Future<void> _onConversationChanged(ConversationChange change) async {
    if (change.participantId != participantId || !change.historyCleared) {
      return;
    }
    if (state.status != ActiveChatStatus.ready) return;
    try {
      final history = await _fetchHistory();
      if (mounted) state = state.copyWith(messages: history);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to reload a deleted chat', e, stackTrace);
    }
  }

  /// Messages sent while the connection was down were not delivered live.
  Future<void> _reloadAfterReconnect() async {
    if (state.status != ActiveChatStatus.ready) return;
    try {
      final history = await _fetchHistory();
      if (!mounted || state.status != ActiveChatStatus.ready) return;
      state = state.copyWith(
        messages: _mergeHistory(history),
        sendError: state.sendError,
      );
      unawaited(conversations.markAsRead(participantId));
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to reload chat after reconnecting',
        e,
        stackTrace,
      );
    }
  }

  Future<List<ChatMessage>> _fetchHistory() async {
    final encrypted = await repository.fetchMessages(participantId);
    final messages = <String, ChatMessage>{};
    for (final stored in encrypted) {
      final message = await _reader.read(stored);
      // A message has one id inside its sealed text: a stored copy of an
      // old message cannot show up a second time.
      messages.putIfAbsent(message.id, () => message);
    }
    return messages.values.toList();
  }

  ChatMessage? _find(String messageId) =>
      state.messages.where((m) => m.id == messageId).firstOrNull;

  /// The server's history, followed by what only this screen knows about:
  /// messages still sending or failed, and ones that arrived live meanwhile.
  List<ChatMessage> _mergeHistory(List<ChatMessage> history) {
    final stored = {for (final message in history) message.id};
    return [
      ...history,
      ...state.messages.where((message) => !stored.contains(message.id)),
    ];
  }

  void _replace(
    ChatMessage message, {
    bool? peerKeyChanged,
    ChatSendProblem? sendError,
  }) {
    state = state.copyWith(
      messages: [
        for (final existing in state.messages)
          existing.id == message.id ? message : existing,
      ],
      peerKeyChanged: peerKeyChanged,
      sendError: sendError,
    );
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}

/// A file waiting to be uploaded with its message.
typedef _OutgoingFile = ({
  Uint8List bytes,
  String name,
  String mimeType,
  ChatVoiceDetails? voice,
});

/// The id of a new message: the server stores one id once.
String _newMessageId() => randomUuid();

/// One notifier per open conversation, disposed when its screen closes.
final activeChatProvider = StateNotifierProvider.autoDispose
    .family<ActiveChatNotifier, ActiveChatState, ChatParticipants>((ref, chat) {
      return ActiveChatNotifier(
        userId: chat.userId,
        participantId: chat.participantId,
        repository: ref.watch(chatRepositoryProvider),
        socketService: ref.watch(chatSocketServiceProvider),
        setupService: ref.watch(e2eeSetupServiceProvider),
        cipher: ref.watch(messageCipherProvider(chat.userId)),
        attachments: ref.watch(chatAttachmentServiceProvider),
        conversations: ref.watch(conversationsProvider.notifier),
      );
    });
