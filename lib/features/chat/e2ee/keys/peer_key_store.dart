import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Remembers, on this device, the public key first seen for each person the
/// signed-in user chats with.
///
/// The server hands out public keys, so a compromised server could hand out
/// its own and read the messages. Keeping the key seen first means a later
/// swap is noticed instead of silently used.
class PeerKeyStore {
  final String userId;
  final FlutterSecureStorage secureStorage;

  PeerKeyStore({
    required this.userId,
    this.secureStorage = const FlutterSecureStorage(),
  });

  String _name(String peerId) => 'peer_key_${userId}_$peerId';

  Future<Uint8List?> read(String peerId) async {
    final stored = await secureStorage.read(key: _name(peerId));
    return stored == null ? null : base64Decode(stored);
  }

  Future<void> write(String peerId, Uint8List publicKey) {
    return secureStorage.write(
      key: _name(peerId),
      value: base64Encode(publicKey),
    );
  }
}
