import 'package:dio/dio.dart';

import 'package:genie/features/chat/data/chat_backup_repository.dart';
import 'package:genie/features/chat/e2ee/keys/crypto_service.dart';
import 'package:genie/features/chat/e2ee/keys/key_service.dart';
import 'package:genie/features/chat/e2ee/keys/message_cipher.dart';
import 'package:genie/features/chat/e2ee/keys/peer_key_store.dart';
import 'package:genie/features/chat/models/chat_models.dart';

/// Words for what a message holds besides text, in the user's language.
typedef ChatPreviewLabels = ({String photo, String voice});

/// Reads a message that arrived inside a push, to write its notification.
class ChatPushPreview {
  /// A notification shows this much of a long message.
  static const maxLength = 300;

  /// Opens a sealed message with the keys on this phone; null when it cannot.
  final Future<OpenedMessage?> Function(EncryptedMessage message) open;

  const ChatPushPreview({required this.open});

  /// Opens messages for [userId] with the keys stored on this phone, using
  /// only what is already trusted here: no network and no signed-in
  /// session, as when the app is closed and a push arrives.
  factory ChatPushPreview.forAccount(String userId, CryptoService crypto) {
    final cipher = MessageCipher(
      userId: userId,
      cryptoService: crypto,
      keyService: KeyService(cryptoService: crypto, dio: Dio()),
      // Never asked: `askServer: false` stays on this phone.
      keyRepository: ChatBackupRepository(dio: Dio()),
      trustedKeys: PeerKeyStore(userId: userId),
    );
    return ChatPushPreview(
      open: (message) => cipher.decrypt(message, askServer: false),
    );
  }

  /// What the notification says about the message, or null when this phone
  /// cannot read it (the notification then says only that one arrived).
  Future<String?> bodyOf({
    required String senderId,
    required String recipientId,
    required String messageId,
    required String ciphertext,
    required String nonce,
    required ChatPreviewLabels labels,
  }) async {
    final opened = await open(
      EncryptedMessage(
        id: messageId,
        senderId: senderId,
        recipientId: recipientId,
        ciphertext: ciphertext,
        nonce: nonce,
        createdAt: DateTime.now(),
      ),
    );
    if (opened == null) return null;

    final attachment = opened.attachment;
    final text = opened.text.trim();
    final kind = switch (attachment) {
      null => null,
      final file when file.isVoice => '\u{1F3A4} ${labels.voice}',
      final file when file.isImage => '\u{1F4F7} ${labels.photo}',
      final file => '\u{1F4CE} ${file.name}',
    };
    final body = switch ((kind, text.isEmpty)) {
      (null, _) => text,
      (final label?, true) => label,
      (final label?, false) => '$label  $text',
    };
    if (body.isEmpty) return null;
    return body.length <= maxLength
        ? body
        : '${body.substring(0, maxLength - 1)}…';
  }
}
