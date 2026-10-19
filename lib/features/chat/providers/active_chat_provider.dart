import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/chat/data/chat_attachment_service.dart';
import 'package:genie/features/chat/data/chat_repository.dart';
import 'package:genie/features/chat/data/chat_socket_service.dart';
import 'package:genie/features/chat/e2ee/e2ee_setup_service.dart';
import 'package:genie/features/chat/e2ee/keys/message_cipher.dart';
import 'package:genie/features/chat/e2ee/backup/pin_check.dart';
import 'package:genie/features/chat/models/chat_models.dart';
import 'package:genie/features/chat/models/chat_send_problem.dart';
import 'package:genie/features/chat/models/chat_voice.dart';
import 'package:genie/features/chat/models/conversation_change.dart';
import 'package:genie/features/chat/providers/active_chat_state.dart';
import 'package:genie/features/chat/providers/chat_provider.dart';
import 'package:genie/features/chat/providers/chat_service_providers.dart';
import 'package:genie/shared/utils/random_uuid.dart';

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
  }) : super(const ActiveChatState()) {
    _subscriptions
      ..add(socketService.onMessage.listen(_queueIncoming))
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

  Future<void> sendMessage(String text) async {
    if (state.status != ActiveChatStatus.ready || state.peerKeyChanged) return;

    final message = ChatMessage(
      id: _newMessageId(),
      senderId: userId,
      recipientId: participantId,
      text: text,
      createdAt: DateTime.now(),
      status: ChatMessageStatus.sending,
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
    await _sendFile(
      (bytes: bytes, name: name, mimeType: mimeType, voice: null),
      localImage: bytes,
    );
  }

  /// Sends a voice message recorded on this device, the same way as a
  /// picture: shown at once, then encrypted, uploaded and announced.
  Future<void> sendVoice(RecordedVoiceNote note) async {
    await _sendFile(
      (
        bytes: note.bytes,
        name: note.fileName,
        mimeType: note.mimeType,
        voice: note.details,
      ),
      localVoice: note,
    );
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
      );
      await socketService.send(
        id: message.id,
        recipientId: participantId,
        ciphertext: sealed.ciphertext,
        nonce: sealed.nonce,
      );
      if (!mounted) return;
      _outgoingFiles.remove(message.id);
      _replace(message.copyWith(status: ChatMessageStatus.sent));
      unawaited(conversations.refresh());
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
      final opened = await cipher.decrypt(encrypted);
      if (!mounted || !_keysReady) return;

      final message = _toMessage(encrypted, opened);
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
      if (opened == null) await _recheckPeerKeyAfterUnreadable();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to show an incoming message', e, stackTrace);
    }
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
      final message = _toMessage(stored, await cipher.decrypt(stored));
      // A message has one id inside its sealed text: a stored copy of an
      // old message cannot show up a second time.
      messages.putIfAbsent(message.id, () => message);
    }
    return messages.values.toList();
  }

  ChatMessage _toMessage(EncryptedMessage encrypted, OpenedMessage? opened) {
    return ChatMessage(
      id: opened?.id ?? encrypted.id,
      senderId: encrypted.senderId,
      recipientId: encrypted.recipientId,
      text: opened?.text ?? undecryptableText,
      createdAt: encrypted.createdAt,
      attachment: opened?.attachment,
    );
  }

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
