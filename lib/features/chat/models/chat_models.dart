import 'dart:typed_data';

import 'package:genie/features/chat/models/chat_attachment.dart';

class ChatConversation {
  /// Shown until the last message has been decrypted on this device.
  static const encryptedPreview = 'Encrypted message';

  /// Shown for a last message that is a picture without a caption.
  static const photoPreview = '\u{1F4F7} Photo';

  final String id;
  final String participantName;
  final String participantId;
  final String? participantAvatar;
  final String lastMessage;
  final String lastMessageTime;
  final int unreadCount;

  /// The last message as stored on the server, for decrypting the preview.
  final String? lastMessageId;
  final String? lastSenderId;
  final String? lastCiphertext;
  final String? lastNonce;

  ChatConversation({
    required this.id,
    required this.participantName,
    required this.participantId,
    this.participantAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.lastMessageId,
    this.lastSenderId,
    this.lastCiphertext,
    this.lastNonce,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final lastMsg = json['lastMessage'];
    final createdAtStr = lastMsg != null ? lastMsg['createdAt'] : null;
    String formattedTime = '';
    if (createdAtStr != null) {
      final dt = DateTime.tryParse(createdAtStr)?.toLocal();
      if (dt != null) {
        final now = DateTime.now();
        if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
          formattedTime =
              '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        } else {
          formattedTime = '${dt.month}/${dt.day}';
        }
      }
    }

    final ciphertext = lastMsg != null
        ? lastMsg['ciphertext'] as String?
        : null;

    return ChatConversation(
      id: json['participantId'] ?? '',
      participantName: json['participantName'] ?? 'Property Owner',
      participantId: json['participantId'] ?? '',
      participantAvatar: json['participantAvatar'],
      lastMessage: ciphertext != null ? encryptedPreview : '',
      lastMessageTime: formattedTime,
      unreadCount: json['unreadCount'] ?? 0,
      lastMessageId: lastMsg != null ? lastMsg['id'] as String? : null,
      lastSenderId: lastMsg != null ? lastMsg['senderId'] as String? : null,
      lastCiphertext: ciphertext,
      lastNonce: lastMsg != null ? lastMsg['nonce'] as String? : null,
    );
  }

  /// The last message in the form it can be decrypted, as seen by [userId].
  /// Null when the server sent no complete last message.
  EncryptedMessage? lastMessageFor(String userId) {
    final id = lastMessageId;
    final senderId = lastSenderId;
    final ciphertext = lastCiphertext;
    final nonce = lastNonce;
    if (id == null || senderId == null || ciphertext == null || nonce == null) {
      return null;
    }
    return EncryptedMessage(
      id: id,
      senderId: senderId,
      recipientId: senderId == participantId ? userId : participantId,
      ciphertext: ciphertext,
      nonce: nonce,
      createdAt: DateTime.now(),
    );
  }

  ChatConversation copyWith({
    String? id,
    String? participantName,
    String? participantId,
    String? participantAvatar,
    String? lastMessage,
    String? lastMessageTime,
    int? unreadCount,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      participantName: participantName ?? this.participantName,
      participantId: participantId ?? this.participantId,
      participantAvatar: participantAvatar ?? this.participantAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessageId: lastMessageId,
      lastSenderId: lastSenderId,
      lastCiphertext: lastCiphertext,
      lastNonce: lastNonce,
    );
  }
}

/// A message as the server stores and delivers it. Only the two people in
/// the conversation can turn it into a [ChatMessage].
class EncryptedMessage {
  final String id;
  final String senderId;
  final String recipientId;
  final String ciphertext;
  final String nonce;
  final DateTime createdAt;

  const EncryptedMessage({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.ciphertext,
    required this.nonce,
    required this.createdAt,
  });

  factory EncryptedMessage.fromJson(Map<String, dynamic> json) {
    return EncryptedMessage(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      recipientId: json['recipientId'] as String,
      ciphertext: json['ciphertext'] as String,
      nonce: json['nonce'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// The other person in the conversation, as seen by [userId].
  String peerOf(String userId) => senderId == userId ? recipientId : senderId;
}

/// Delivery state of a message on this device.
enum ChatMessageStatus { sending, sent, failed }

/// One decrypted chat message.
class ChatMessage {
  final String id;
  final String senderId;
  final String recipientId;
  final String text;
  final DateTime createdAt;
  final ChatMessageStatus status;

  /// A file sent with the message, once it is stored on the server.
  final ChatAttachment? attachment;

  /// The picture being sent from this device, shown until it is uploaded
  /// and kept so a failed send can be retried.
  final Uint8List? localImage;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.text,
    required this.createdAt,
    this.status = ChatMessageStatus.sent,
    this.attachment,
    this.localImage,
  });

  ChatMessage copyWith({
    String? id,
    DateTime? createdAt,
    ChatMessageStatus? status,
    ChatAttachment? attachment,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId,
      recipientId: recipientId,
      text: text,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      attachment: attachment ?? this.attachment,
      localImage: localImage,
    );
  }
}
