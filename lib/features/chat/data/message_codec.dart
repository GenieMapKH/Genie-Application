import 'dart:convert';
import 'package:tilomnov/features/chat/models/chat_attachment.dart';
import 'package:tilomnov/features/chat/models/chat_listing.dart';
import 'package:tilomnov/features/chat/models/chat_models.dart';

typedef OpenedMessage = ({
  String? id,
  String text,
  ChatAttachment? attachment,
  String? replyToId,
  ChatListing? listing,
});

/// Managed message transport. Storage encryption belongs to the authenticated server.
class MessageCodec {
  static const _envelopeVersion = 1;
  final String userId;
  const MessageCodec({required this.userId});

  /// Encodes content for authenticated transport; the server encrypts it at rest.
  Future<({String ciphertext, String nonce})> encode(
    String text, {
    required String id,
    required String peerId,
    ChatAttachment? attachment,
    String? replyToId,
    ChatListing? listing,
  }) async {
    return (
      ciphertext: base64Encode(
        utf8.encode(
          jsonEncode({
            'v': _envelopeVersion,
            'id': id,
            'from': userId,
            'to': peerId,
            'text': text,
            'file': ?attachment?.toJson(),
            're': ?replyToId,
            'listing': ?listing?.toJson(),
          }),
        ),
      ),
      nonce: 'managed-v1',
    );
  }

  /// Old ciphertext stays stored, but is deliberately inaccessible in this app.
  Future<OpenedMessage?> decode(EncryptedMessage message) async {
    if (message.nonce != 'managed-v1' ||
        (message.senderId != userId && message.recipientId != userId)) {
      return null;
    }
    final Object? envelope;
    try {
      envelope = jsonDecode(utf8.decode(base64Decode(message.ciphertext)));
    } on FormatException {
      return null;
    }
    if (envelope is! Map || envelope['v'] != _envelopeVersion) return null;
    final id = envelope['id'];
    final text = envelope['text'];
    final replyToId = envelope['re'];
    final labelledHonestly =
        envelope['from'] == message.senderId &&
        envelope['to'] == message.recipientId;
    if (!labelledHonestly ||
        id is! String ||
        id != message.id ||
        text is! String) {
      return null;
    }
    final attachment = ChatAttachment.tryParse(envelope['file']);
    final attachmentIsTheirs =
        attachment == null ||
        attachment.belongsTo(
          senderId: message.senderId,
          recipientId: message.recipientId,
        );
    return (
      id: id,
      text: text,
      attachment: attachmentIsTheirs ? attachment : null,
      replyToId: replyToId is String ? replyToId : null,
      listing: ChatListing.tryParse(envelope['listing']),
    );
  }
}
