import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/core/errors/app_exceptions.dart';
import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/chat/data/chat_attachment_service.dart';
import 'package:genie/features/chat/data/chat_repository.dart';
import 'package:genie/features/chat/data/chat_socket_service.dart';
import 'package:genie/features/chat/e2ee/e2ee_setup_service.dart';
import 'package:genie/features/chat/e2ee/message_cipher.dart';
import 'package:genie/features/chat/models/chat_models.dart';
import 'package:genie/features/chat/providers/active_chat_state.dart';
import 'package:genie/features/chat/providers/chat_provider.dart';
import 'package:genie/features/chat/providers/chat_service_providers.dart';

export 'active_chat_state.dart';

/// Loads, receives and sends the messages of one conversation.
class ActiveChatNotifier extends StateNotifier<ActiveChatState> {
  static const undecryptableText =
      'This message cannot be read on this device.';

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

  /// Name and type of pictures still being sent, by message id.
  final _outgoingFiles = <String, ({String name, String mimeType})>{};

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
      ..add(socketService.onConnected.listen((_) => _reloadAfterReconnect()));
  }

  /// Makes encryption ready, then loads the conversation. [askPin] is used
  /// only for an account with a backup PIN on a device without its keys.
  /// [takeOver] is the user's answer to [E2eeSetupResult.usedOnAnotherDevice].
  Future<void> open({required PinPrompt askPin, bool takeOver = false}) async {
    _keysReady = false;
    state = const ActiveChatState();
    try {
      final result = await setupService.initialize(
        userId,
        askPin: askPin,
        takeOver: takeOver,
      );
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
    if (state.status != ActiveChatStatus.ready || state.peerKeyChanged) return;

    final message = ChatMessage(
      id: _newMessageId(),
      senderId: userId,
      recipientId: participantId,
      text: '',
      createdAt: DateTime.now(),
      status: ChatMessageStatus.sending,
      localImage: bytes,
    );
    _outgoingFiles[message.id] = (name: name, mimeType: mimeType);
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
      state = state.copyWith(
        sendError: 'Could not reach the server. Check your connection.',
      );
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
        sendError: e is AppException
            ? e.message
            : 'Message not sent. Please try again.',
      );
    }
  }

  /// Uploads the picture of a message that has one and is not stored yet.
  /// A retry after a later failure does not upload it a second time.
  Future<ChatMessage> _uploadPendingFile(ChatMessage message) async {
    final bytes = message.localImage;
    final file = _outgoingFiles[message.id];
    if (message.attachment != null || bytes == null || file == null) {
      return message;
    }

    final attachment = await attachments.send(
      bytes,
      recipientId: participantId,
      name: file.name,
      mimeType: file.mimeType,
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
    String? sendError,
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

/// A random (version 4) UUID, which the server accepts as a message id.
String _newMessageId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

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
