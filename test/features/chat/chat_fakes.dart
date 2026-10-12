import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/chat/data/chat_repository.dart';
import 'package:genie/features/chat/data/chat_socket_service.dart';
import 'package:genie/features/chat/e2ee/e2ee_setup_service.dart';
import 'package:genie/features/chat/e2ee/message_cipher.dart';
import 'package:genie/features/chat/models/chat_models.dart';
import 'package:genie/features/chat/models/chat_participant.dart';

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

  @override
  String get userId => me;

  @override
  Future<({String ciphertext, String nonce})> encrypt(
    String text, {
    required String id,
    required String peerId,
  }) async {
    if (encryptError != null) throw encryptError!;
    if (peerKeyStatus == PeerKeyStatus.changed) {
      throw const PeerKeyChangedException();
    }
    return (ciphertext: 'sealed:$text', nonce: 'nonce');
  }

  @override
  Future<OpenedMessage?> decrypt(EncryptedMessage message) async {
    return message.ciphertext.startsWith('sealed:')
        ? (id: message.id, text: message.ciphertext.substring(7))
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

class FakeChatRepository extends Fake implements ChatRepository {
  List<ChatConversation> conversations = [];
  List<EncryptedMessage> history = [];
  Object? conversationsError;
  ChatParticipantProfile? participant;

  /// When set, requests wait here until the test completes it.
  Completer<void>? gate;

  int conversationRequests = 0;
  int historyRequests = 0;
  final markedRead = <String>[];

  @override
  Future<List<ChatConversation>> fetchConversations() async {
    conversationRequests++;
    await gate?.future;
    if (conversationsError != null) throw conversationsError!;
    return conversations;
  }

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
  final sent = <EncryptedMessage>[];
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
  }) async {
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
  Future<E2eeSetupResult> initialize(
    String userId, {
    required PinPrompt askPin,
  }) async {
    runs++;
    return result;
  }
}

Future<String?> neverAskPin({required bool isNewPin}) async =>
    fail('must not ask for a PIN');
