import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/chat/data/chat_attachment_service.dart';
import 'package:genie/features/chat/data/chat_repository.dart';
import 'package:genie/features/chat/data/chat_socket_service.dart';
import 'package:genie/features/chat/e2ee/e2ee_setup_service.dart';
import 'package:genie/features/chat/e2ee/keys/message_cipher.dart';
import 'package:genie/features/chat/e2ee/backup/pin_check.dart';
import 'package:genie/features/chat/models/chat_attachment.dart';
import 'package:genie/features/chat/models/chat_call_entry.dart';
import 'package:genie/features/chat/models/chat_models.dart';
import 'package:genie/features/chat/models/chat_participant.dart';
import 'package:genie/features/chat/models/chat_voice.dart';
import 'package:genie/features/chat/models/conversation_change.dart';
import 'package:genie/features/chat/models/message_deletion.dart';
import 'package:genie/features/chat/models/chat_listing.dart';

const me = 'user-me';
const peer = 'user-peer';

/// A stored message whose "ciphertext" [FakeCipher] can read back.
EncryptedMessage encrypted(
  String id,
  String text, {
  required String from,
  String? to,
}) {
  return EncryptedMessage(
    id: id,
    senderId: from,
    recipientId: to ?? (from == me ? peer : me),
    ciphertext: 'sealed:$text',
    nonce: 'nonce',
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

/// "Encrypts" by prefixing, so tests can tell sealed text from plain text.
class FakeCipher extends Fake implements MessageCipher {
  Object? encryptError;

  /// What the server would say about the other person's key.
  PeerKeyStatus peerKeyStatus = PeerKeyStatus.trusted;
  int keyChecks = 0;
  int acceptedKeys = 0;

  /// The attachment sealed into each message, in sending order.
  final sealedAttachments = <ChatAttachment?>[];

  /// Attachments that incoming messages carry, by message id.
  final incomingAttachments = <String, ChatAttachment>{};

  /// The message each message replies to, as sealed inside it, by id.
  final sealedReplies = <String, String>{};

  /// The listing card sealed into each message, by message id.
  final sealedListings = <String, ChatListing?>{};

  @override
  String get userId => me;

  @override
  Future<({String ciphertext, String nonce})> encrypt(
    String text, {
    required String id,
    required String peerId,
    ChatAttachment? attachment,
    String? replyToId,
    ChatListing? listing,
  }) async {
    if (encryptError != null) throw encryptError!;
    sealedAttachments.add(attachment);
    sealedListings[id] = listing;
    if (replyToId != null) sealedReplies[id] = replyToId;
    if (peerKeyStatus == PeerKeyStatus.changed) {
      throw const PeerKeyChangedException();
    }
    return (ciphertext: 'sealed:$text', nonce: 'nonce');
  }

  /// How many messages were opened.
  int decrypts = 0;

  @override
  Future<OpenedMessage?> decrypt(
    EncryptedMessage message, {
    bool askServer = true,
  }) async {
    decrypts++;
    return message.ciphertext.startsWith('sealed:')
        ? (
            id: message.id,
            text: message.ciphertext.substring(7),
            attachment: incomingAttachments[message.id],
            replyToId: sealedReplies[message.id],
            listing: sealedListings[message.id],
          )
        : null;
  }

  @override
  Future<PeerKeyStatus> checkPeerKey(String peerId) async {
    keyChecks++;
    return peerKeyStatus;
  }

  @override
  Future<void> trustCurrentPeerKey(String peerId) async {
    acceptedKeys++;
    peerKeyStatus = PeerKeyStatus.trusted;
  }

  @override
  Future<String?> safetyCode(String peerId) async =>
      '11111 22222 33333 44444 55555 66666';
}

/// Pretends to encrypt and upload: remembers what was sent and can fail.
class FakeAttachmentService extends Fake implements ChatAttachmentService {
  final uploads = <Uint8List>[];
  final files = <String, Uint8List>{};
  Object? uploadError;

  @override
  Future<ChatAttachment> send(
    Uint8List bytes, {
    required String recipientId,
    required String name,
    required String mimeType,
    ChatVoiceDetails? voice,
  }) async {
    if (uploadError != null) throw uploadError!;
    uploads.add(bytes);
    return fakeAttachment(
      uploads.length,
      name: name,
      mimeType: mimeType,
      voice: voice,
    );
  }

  /// Nothing is ready without waiting: pictures go through loading.
  @override
  Uint8List? cached(ChatAttachment attachment) => null;

  @override
  Future<Uint8List> open(ChatAttachment attachment) async {
    final bytes = files[attachment.path];
    if (bytes == null) throw Exception('file not found');
    return bytes;
  }
}

ChatAttachment fakeAttachment(
  int n, {
  String name = 'photo.png',
  String mimeType = 'image/png',
  ChatVoiceDetails? voice,
}) {
  final id = n.toString().padLeft(12, '0');
  return ChatAttachment(
    path:
        '11111111-1111-4111-8111-111111111111/'
        '22222222-2222-4222-8222-222222222222/'
        '33333333-3333-4333-8333-$id',
    key: 'key-$n',
    nonce: 'nonce-$n',
    name: name,
    mimeType: mimeType,
    size: 68,
    voice: voice,
  );
}

/// A 1x1 transparent PNG: the smallest picture Flutter can decode.
final tinyPng = Uint8List.fromList(const [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

class FakeChatRepository extends Fake implements ChatRepository {
  List<ChatConversation> conversations = [];
  List<ChatConversation> archivedConversations = [];

  /// Archive, unarchive and delete calls, e.g. "archive peer-1" or
  /// "delete peer-1 forEveryone".
  final conversationChanges = <String>[];

  /// When set, archive, unarchive and delete fail with it.
  Object? changeError;
  List<EncryptedMessage> history = [];
  Object? conversationsError;
  ChatParticipantProfile? participant;

  /// When set, requests wait here until the test completes it.
  Completer<void>? gate;

  /// The calls the server lists for any conversation.
  List<ChatCallEntry> callHistory = [];
  int callHistoryRequests = 0;

  int conversationRequests = 0;
  int historyRequests = 0;
  final markedRead = <String>[];

  @override
  Future<List<ChatCallEntry>> fetchCallHistory(String participantId) async {
    callHistoryRequests++;
    return callHistory;
  }

  /// The cursor of each page asked for (null for the first).
  final conversationCursors = <String?>[];

  /// Serves [conversations] (or [archivedConversations]) a page at a time,
  /// in their order; the cursor is the index the next page starts at.
  @override
  Future<ConversationPage> fetchConversationPage({
    bool archived = false,
    int limit = ChatRepository.conversationPageSize,
    String? cursor,
  }) async {
    conversationRequests++;
    conversationCursors.add(cursor);
    await gate?.future;
    if (conversationsError != null) throw conversationsError!;
    final all = archived ? archivedConversations : conversations;
    final start = cursor == null ? 0 : int.parse(cursor);
    final end = (start + limit).clamp(0, all.length);
    return (
      items: all.sublist(start.clamp(0, end), end),
      nextCursor: end < all.length ? '$end' : null,
      unreadTotal: all.fold(0, (sum, c) => sum + c.unreadCount),
    );
  }

  Future<void> _change(String change) async {
    if (changeError != null) throw changeError!;
    conversationChanges.add(change);
  }

  @override
  Future<void> archiveConversation(String participantId) =>
      _change('archive $participantId');

  @override
  Future<void> unarchiveConversation(String participantId) =>
      _change('unarchive $participantId');

  @override
  Future<void> deleteConversation(
    String participantId, {
    required bool forEveryone,
  }) => _change('delete $participantId${forEveryone ? ' forEveryone' : ''}');

  @override
  Future<List<EncryptedMessage>> fetchMessages(String participantId) async {
    historyRequests++;
    await gate?.future;
    return history;
  }

  @override
  Future<void> markAsRead(String participantId) async {
    markedRead.add(participantId);
  }

  /// Edits and deletes, e.g. "edit m1 sealed:new" or "delete m1 forEveryone".
  final messageChanges = <String>[];

  /// When set, editing and deleting a message fail with it.
  Object? messageChangeError;

  @override
  Future<EncryptedMessage> editMessage(
    String messageId, {
    required String ciphertext,
    required String nonce,
  }) async {
    if (messageChangeError != null) throw messageChangeError!;
    messageChanges.add('edit $messageId $ciphertext');
    return EncryptedMessage(
      id: messageId,
      senderId: me,
      recipientId: peer,
      ciphertext: ciphertext,
      nonce: nonce,
      createdAt: DateTime.utc(2026, 1, 1),
      editedAt: DateTime.utc(2026, 1, 1, 0, 30),
    );
  }

  @override
  Future<void> deleteMessage(
    String messageId, {
    required bool forEveryone,
    String? attachmentPath,
  }) async {
    if (messageChangeError != null) throw messageChangeError!;
    messageChanges.add(
      'delete $messageId${forEveryone ? ' forEveryone' : ''}'
      '${attachmentPath != null ? ' $attachmentPath' : ''}',
    );
  }

  @override
  Future<ChatParticipantProfile> fetchParticipantProfile(String userId) async {
    return participant ??
        ChatParticipantProfile(id: userId, memberSince: DateTime.utc(2025, 3));
  }
}

class FakeChatSocket extends Fake implements ChatSocketService {
  final messages = StreamController<EncryptedMessage>.broadcast();
  final connections = StreamController<void>.broadcast();
  final presence = StreamController<ChatPresence>.broadcast();
  final conversationChanges = StreamController<ConversationChange>.broadcast();
  final callEvents = StreamController<CallSocketEvent>.broadcast();
  final editedMessages = StreamController<EncryptedMessage>.broadcast();
  final deletedMessages = StreamController<MessageDeletion>.broadcast();
  final sent = <EncryptedMessage>[];

  /// The reply each sent message named, by message id.
  final sentReplyIds = <String, String>{};
  final watching = <String>[];
  Object? sendError;

  /// What a presence watch is answered with.
  ChatPresence Function(String userId) presenceOf = (userId) =>
      ChatPresence(userId: userId, online: false);

  @override
  Stream<EncryptedMessage> get onMessage => messages.stream;

  @override
  Stream<void> get onConnected => connections.stream;

  @override
  Stream<ChatPresence> get onPresence => presence.stream;

  @override
  Stream<CallSocketEvent> get onCallEvent => callEvents.stream;

  @override
  Stream<EncryptedMessage> get onMessageEdited => editedMessages.stream;

  @override
  Stream<MessageDeletion> get onMessageDeleted => deletedMessages.stream;

  @override
  Stream<ConversationChange> get onConversationChanged =>
      conversationChanges.stream;

  @override
  Future<ChatPresence> watchPresence(String userId) async {
    watching.add(userId);
    return presenceOf(userId);
  }

  @override
  void unwatchPresence(String userId) => watching.remove(userId);

  @override
  Future<EncryptedMessage> send({
    required String id,
    required String recipientId,
    required String ciphertext,
    required String nonce,
    String? replyToId,
  }) async {
    if (replyToId != null) sentReplyIds[id] = replyToId;
    final message = EncryptedMessage(
      id: id,
      senderId: me,
      recipientId: recipientId,
      ciphertext: ciphertext,
      nonce: nonce,
      createdAt: DateTime.utc(2026, 1, 2),
    );
    sent.add(message);
    if (sendError != null) throw sendError!;
    return message;
  }
}

class FakeSetupService extends Fake implements E2eeSetupService {
  E2eeSetupResult result = E2eeSetupResult.ready;
  int runs = 0;

  @override
  Future<E2eeSetupResult> initialize(String userId, {PinPrompt? askPin}) async {
    runs++;
    return result;
  }
}

Future<bool> neverAskPin(PinCheck check) async =>
    fail('must not ask for a PIN');
