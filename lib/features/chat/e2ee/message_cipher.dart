import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:genie/core/errors/app_exceptions.dart';
import 'package:genie/features/chat/data/chat_backup_repository.dart';
import 'package:genie/features/chat/e2ee/crypto_service.dart';
import 'package:genie/features/chat/e2ee/key_service.dart';
import 'package:genie/features/chat/e2ee/peer_key_store.dart';
import 'package:genie/features/chat/models/chat_models.dart';

/// Thrown when a message cannot be encrypted for the other person.
class ChatEncryptionException extends AppException {
  const ChatEncryptionException(super.message);
}

/// Thrown instead of encrypting with a key this device has never trusted.
class PeerKeyChangedException extends ChatEncryptionException {
  const PeerKeyChangedException()
    : super('Their security key has changed. Accept the new key to continue.');
}

/// How the key the server lists for someone compares with the trusted one.
enum PeerKeyStatus {
  /// The trusted key (or the first one ever seen, which is now trusted).
  trusted,

  /// The server lists a different key than the one this device trusts.
  changed,

  /// They have not set up secure chat.
  missing,
}

/// A decrypted message. [id] is the id the sender gave it, or null for a
/// message from before messages carried one.
typedef OpenedMessage = ({String? id, String text});

/// Encrypts and decrypts the messages of one signed-in user.
///
/// A message is sealed with this user's secret key and the other person's
/// public key. The same two keys open it, whichever of them sent it, so the
/// sender and recipient are written inside the sealed text: the server
/// cannot pass one person's message off as the other's.
class MessageCipher {
  static const _envelopeVersion = 1;

  /// How long a key check is relied on before sending asks the server again.
  static const _checkMaxAge = Duration(minutes: 5);

  final String userId;
  final CryptoService cryptoService;
  final KeyService keyService;
  final ChatBackupRepository keyRepository;
  final PeerKeyStore trustedKeys;
  final DateTime Function() _now;

  final _trusted = <String, Uint8List>{};
  final _lastCheck = <String, ({PeerKeyStatus status, DateTime at})>{};

  MessageCipher({
    required this.userId,
    required this.cryptoService,
    required this.keyService,
    required this.keyRepository,
    required this.trustedKeys,
    DateTime Function() now = DateTime.now,
  }) : _now = now;

  /// Asks the server for [peerId]'s key and compares it with the trusted
  /// one. The first key ever seen for someone becomes the trusted one.
  Future<PeerKeyStatus> checkPeerKey(String peerId) async {
    final status = await _compareWithServer(peerId);
    _lastCheck[peerId] = (status: status, at: _now());
    return status;
  }

  /// Trusts the key the server currently lists for [peerId]. Only called
  /// when the user has agreed to it.
  Future<void> trustCurrentPeerKey(String peerId) async {
    final current = base64Decode(await keyRepository.fetchPublicKey(peerId));
    await _trust(peerId, current);
    _lastCheck[peerId] = (status: PeerKeyStatus.trusted, at: _now());
  }

  /// A short code that is the same on both phones only if each has the
  /// other's real key. Null until both keys are known on this device.
  Future<String?> safetyCode(String peerId) async {
    final keyPair = await keyService.getIdentityKeyPair(userId);
    final peerKey = await _trustedKey(peerId);
    if (keyPair == null || peerKey == null) return null;

    final hash = cryptoService.fingerprint(keyPair.publicKey, peerKey);
    final groups = <String>[];
    for (var i = 0; i < 30; i += 5) {
      final number = hash
          .sublist(i, i + 5)
          .fold<int>(0, (value, byte) => (value << 8) | byte);
      groups.add((number % 100000).toString().padLeft(5, '0'));
    }
    return groups.join(' ');
  }

  /// Seals [text] for [peerId]. [id] is the message's id; it travels inside
  /// the sealed text so a stored copy cannot be replayed as a new message.
  Future<({String ciphertext, String nonce})> encrypt(
    String text, {
    required String id,
    required String peerId,
  }) async {
    final keyPair = await keyService.getIdentityKeyPair(userId);
    if (keyPair == null) {
      throw const ChatEncryptionException(
        'Secure chat is not set up on this device.',
      );
    }

    switch (await _recentStatus(peerId)) {
      case PeerKeyStatus.changed:
        throw const PeerKeyChangedException();
      case PeerKeyStatus.missing:
        throw const ChatEncryptionException(
          'This person has not set up secure chat yet, so they cannot '
          'receive messages.',
        );
      case PeerKeyStatus.trusted:
    }

    final sealed = cryptoService.encryptMessage(
      jsonEncode({
        'v': _envelopeVersion,
        'id': id,
        'from': userId,
        'to': peerId,
        'text': text,
      }),
      (await _trustedKey(peerId))!,
      keyPair.secretKey,
    );
    return (ciphertext: sealed['ciphertext']!, nonce: sealed['nonce']!);
  }

  /// The readable message, or null when this device cannot or must not
  /// show it: its keys are missing, either person has replaced theirs since,
  /// or the message is not from who the server says it is.
  Future<OpenedMessage?> decrypt(EncryptedMessage message) async {
    final keyPair = await keyService.getIdentityKeyPair(userId);
    if (keyPair == null) return null;

    final peerId = message.peerOf(userId);
    var peerKey = await _trustedKey(peerId);
    if (peerKey == null) {
      try {
        await checkPeerKey(peerId);
      } on DioException {
        return null;
      }
      peerKey = await _trustedKey(peerId);
      if (peerKey == null) return null;
    }

    final String opened;
    try {
      opened = cryptoService.decryptMessage(
        message.ciphertext,
        message.nonce,
        peerKey,
        keyPair.secretKey,
      );
    } catch (_) {
      // Sealed with a different key, or tampered with.
      return null;
    }
    return _readEnvelope(opened, message);
  }

  OpenedMessage? _readEnvelope(String opened, EncryptedMessage message) {
    Object? envelope;
    try {
      envelope = jsonDecode(opened);
    } on FormatException {
      envelope = null;
    }
    if (envelope is! Map || envelope['v'] != _envelopeVersion) {
      // Sent before messages named their sender: the text is the message.
      return (id: null, text: opened);
    }

    final id = envelope['id'];
    final text = envelope['text'];
    final labelledHonestly =
        envelope['from'] == message.senderId &&
        envelope['to'] == message.recipientId;
    if (!labelledHonestly || id is! String || text is! String) return null;
    return (id: id, text: text);
  }

  Future<PeerKeyStatus> _recentStatus(String peerId) async {
    final last = _lastCheck[peerId];
    if (last != null && _now().difference(last.at) < _checkMaxAge) {
      return last.status;
    }
    try {
      return await checkPeerKey(peerId);
    } on DioException {
      throw const ChatEncryptionException(
        'Could not reach the server. Check your connection.',
      );
    }
  }

  Future<PeerKeyStatus> _compareWithServer(String peerId) async {
    final Uint8List serverKey;
    try {
      serverKey = base64Decode(await keyRepository.fetchPublicKey(peerId));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return PeerKeyStatus.missing;
      rethrow;
    }

    final trusted = await _trustedKey(peerId);
    if (trusted == null) {
      await _trust(peerId, serverKey);
      return PeerKeyStatus.trusted;
    }
    return listEquals(trusted, serverKey)
        ? PeerKeyStatus.trusted
        : PeerKeyStatus.changed;
  }

  Future<Uint8List?> _trustedKey(String peerId) async {
    final cached = _trusted[peerId];
    if (cached != null) return cached;

    final stored = await trustedKeys.read(peerId);
    if (stored != null) _trusted[peerId] = stored;
    return stored;
  }

  Future<void> _trust(String peerId, Uint8List key) async {
    await trustedKeys.write(peerId, key);
    _trusted[peerId] = key;
  }
}
