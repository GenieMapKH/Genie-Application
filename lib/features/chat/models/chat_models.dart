import 'dart:typed_data';

import 'package:genie/features/chat/models/chat_attachment.dart';
import 'package:genie/features/chat/models/chat_voice.dart';

class ChatConversation {
  /// Shown until the last message has been decrypted on this device.
  static const encryptedPreview = 'Encrypted message';

  /// Shown for a last message that is a picture without a caption.
  static const photoPreview = '\u{1F4F7} Photo';

  /// Shown for a last message that is a voice message.
  static const voicePreview = '\u{1F3A4} Voice message';

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
    final createdAt = createdAtStr is String
        ? DateTime.tryParse(createdAtStr)
        : null;
    final formattedTime = createdAt == null ? '' : _timeOf(createdAt);

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

  /// "14:05" for today, "10/3" for an earlier day.
  static String _timeOf(DateTime moment) {
    final dt = moment.toLocal();
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.month}/${dt.day}';
  }

  /// This conversation once [message] arrived in it: it becomes the last
  /// message (shown as [encryptedPreview] until it is decrypted), and one
  /// more is unread when the other person sent it.
  ChatConversation withNewMessage(EncryptedMessage message) {
    return ChatConversation(
      id: id,
      participantName: participantName,
      participantId: participantId,
      participantAvatar: participantAvatar,
      lastMessage: encryptedPreview,
      lastMessageTime: _timeOf(message.createdAt),
      unreadCount: message.senderId == participantId
          ? unreadCount + 1
          : unreadCount,
      lastMessageId: message.id,
      lastSenderId: message.senderId,
      lastCiphertext: message.ciphertext,
      lastNonce: message.nonce,
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
  /// Stands in for a message this device cannot decrypt. The bubble shows
  /// it in the user's language.
  static const undecryptableText =
      'This message cannot be read on this device.';

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

  /// The voice message being sent from this device, kept the same way.
  final RecordedVoiceNote? localVoice;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.text,
    required this.createdAt,
    this.status = ChatMessageStatus.sent,
    this.attachment,
    this.localImage,
    this.localVoice,
  });

  /// The voice message's length and waveform, whether it is still being
  /// sent from this device or arrived. Null for any other message.
  ChatVoiceDetails? get voice {
    final attachment = this.attachment;
    return localVoice?.details ??
        (attachment != null && attachment.isVoice ? attachment.voice : null);
  }

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
      localVoice: localVoice,
    );
  }
}
