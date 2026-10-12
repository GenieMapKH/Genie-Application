// Runs the chat encryption against the real libsodium instead of fakes.
//
// Skipped unless LIBSODIUM_DLL points at a libsodium binary for this
// machine (e.g. libsodium.dll from the official release), because the
// library is only bundled with the app on a device:
//
//   $env:LIBSODIUM_DLL = 'C:\path\to\libsodium.dll'
//   flutter test test/features/chat/real_crypto_test.dart

// The FFI entry point lives in `sodium`, which `sodium_libs` depends on.
// ignore_for_file: depend_on_referenced_packages
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/chat/data/chat_backup_repository.dart';
import 'package:genie/features/chat/e2ee/backup_service.dart';
import 'package:genie/features/chat/e2ee/crypto_service.dart';
import 'package:genie/features/chat/e2ee/key_service.dart';
import 'package:genie/features/chat/e2ee/message_cipher.dart';
import 'package:genie/features/chat/e2ee/peer_key_store.dart';
import 'package:genie/features/chat/models/chat_models.dart';
import 'package:sodium/sodium.ffi.dart' as ffi;
import 'package:sodium_libs/sodium_libs.dart';

/// Each user's real key pair, as the device would hold it.
class _DeviceKeys extends Fake implements KeyService {
  final Map<String, KeyPair> keyPairs;
  _DeviceKeys(this.keyPairs);

  @override
  Future<KeyPair?> getIdentityKeyPair(String userId) async => keyPairs[userId];
}

/// The server's key directory. A test can make it lie.
class _KeyServer extends Fake implements ChatBackupRepository {
  final listed = <String, Uint8List>{};

  @override
  Future<String> fetchPublicKey(String userId) async {
    final key = listed[userId];
    if (key == null) {
      final options = RequestOptions(path: '/chat/keys/$userId');
      throw DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 404),
      );
    }
    return base64Encode(key);
  }
}

class _MemoryKeyStore extends Fake implements PeerKeyStore {
  final keys = <String, Uint8List>{};

  @override
  Future<Uint8List?> read(String peerId) async => keys[peerId];

  @override
  Future<void> write(String peerId, Uint8List publicKey) async =>
      keys[peerId] = publicKey;
}

void main() {
  final dllPath = Platform.environment['LIBSODIUM_DLL'];
  if (dllPath == null) {
    test(
      'real libsodium',
      () {},
      skip: 'set LIBSODIUM_DLL to run against the real library',
    );
    return;
  }

  const alice = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  const bob = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

  late CryptoService crypto;
  late KeyPair aliceKeys;
  late KeyPair bobKeys;
  late KeyPair attackerKeys;
  late _KeyServer server;
  late MessageCipher aliceCipher;
  late MessageCipher bobCipher;

  MessageCipher cipherFor(String userId, KeyPair keyPair) => MessageCipher(
    userId: userId,
    cryptoService: crypto,
    keyService: _DeviceKeys({userId: keyPair}),
    keyRepository: server,
    trustedKeys: _MemoryKeyStore(),
  );

  Future<EncryptedMessage> sentByAlice(String id, String text) async {
    final sealed = await aliceCipher.encrypt(text, id: id, peerId: bob);
    return EncryptedMessage(
      id: id,
      senderId: alice,
      recipientId: bob,
      ciphertext: sealed.ciphertext,
      nonce: sealed.nonce,
      createdAt: DateTime.utc(2026),
    );
  }

  setUpAll(() async {
    crypto = CryptoService(
      await ffi.SodiumInit.init(() => DynamicLibrary.open(dllPath)),
    );
  });

  setUp(() {
    aliceKeys = crypto.generateKeyPair();
    bobKeys = crypto.generateKeyPair();
    attackerKeys = crypto.generateKeyPair();
    server = _KeyServer()
      ..listed[alice] = aliceKeys.publicKey
      ..listed[bob] = bobKeys.publicKey;
    aliceCipher = cipherFor(alice, aliceKeys);
    bobCipher = cipherFor(bob, bobKeys);
  });

  test(
    'a message is unreadable on the wire and readable by both people',
    () async {
      const text = 'Meet at the villa at 5pm. ជួបគ្នា 🏡';
      final message = await sentByAlice('m1', text);

      final wire = utf8.decode(
        base64Decode(message.ciphertext),
        allowMalformed: true,
      );
      expect(wire, isNot(contains('villa')));
      expect(await bobCipher.decrypt(message), (id: 'm1', text: text));
      expect(await aliceCipher.decrypt(message), (id: 'm1', text: text));
    },
  );

  test('the same text never produces the same ciphertext', () async {
    final first = await sentByAlice('m1', 'hello');
    final second = await sentByAlice('m2', 'hello');

    expect(first.nonce, isNot(second.nonce));
    expect(first.ciphertext, isNot(second.ciphertext));
  });

  test('someone with the ciphertext but neither key cannot read it', () async {
    final message = await sentByAlice('m1', 'the door code is 4471');
    final attackerAsBob = cipherFor(bob, attackerKeys);

    expect(await attackerAsBob.decrypt(message), isNull);
  });

  test('one changed bit makes a message unreadable, not different', () async {
    final message = await sentByAlice('m1', 'pay 500');
    final bytes = base64Decode(message.ciphertext);
    bytes[bytes.length ~/ 2] ^= 0x01;

    final tampered = EncryptedMessage(
      id: message.id,
      senderId: message.senderId,
      recipientId: message.recipientId,
      ciphertext: base64Encode(bytes),
      nonce: message.nonce,
      createdAt: message.createdAt,
    );

    expect(await bobCipher.decrypt(tampered), isNull);
  });

  test("the server cannot pass my message off as the other person's", () async {
    final message = await sentByAlice('m1', 'I agree to the price');

    final reflected = EncryptedMessage(
      id: 'm2',
      senderId: bob,
      recipientId: alice,
      ciphertext: message.ciphertext,
      nonce: message.nonce,
      createdAt: message.createdAt,
    );

    expect(await aliceCipher.decrypt(reflected), isNull);
  });

  test('a key swapped by the server is noticed and nothing is sent', () async {
    await sentByAlice('m1', 'hello');
    server.listed[bob] = attackerKeys.publicKey;

    expect(await aliceCipher.checkPeerKey(bob), PeerKeyStatus.changed);
    await expectLater(
      aliceCipher.encrypt('my passport number', id: 'm2', peerId: bob),
      throwsA(isA<PeerKeyChangedException>()),
    );
  });

  test('the security code matches only when nobody is in between', () async {
    await aliceCipher.checkPeerKey(bob);
    await bobCipher.checkPeerKey(alice);

    final honest = await aliceCipher.safetyCode(bob);
    expect(honest, matches(RegExp(r'^\d{5}( \d{5}){5}$')));
    expect(await bobCipher.safetyCode(alice), honest);

    // A man in the middle gives each side his own key instead.
    server
      ..listed[alice] = attackerKeys.publicKey
      ..listed[bob] = attackerKeys.publicKey;
    final interceptedAlice = cipherFor(alice, aliceKeys);
    final interceptedBob = cipherFor(bob, bobKeys);
    await interceptedAlice.checkPeerKey(bob);
    await interceptedBob.checkPeerKey(alice);

    expect(
      await interceptedAlice.safetyCode(bob),
      isNot(await interceptedBob.safetyCode(alice)),
    );
  });

  test('a secret key is recognised only with its own public key', () {
    expect(crypto.isKeyPair(aliceKeys.publicKey, aliceKeys.secretKey), isTrue);
    expect(crypto.isKeyPair(bobKeys.publicKey, aliceKeys.secretKey), isFalse);
  });

  test('a key restored from its PIN backup still opens old messages', () async {
    final message = await sentByAlice('m1', 'before the new phone');
    final backups = BackupService();

    final backup = await backups.createBackup(
      '482913',
      bobKeys.secretKey.extractBytes(),
    );
    final restoredBytes = await backups.restoreBackup(
      '482913',
      backup['salt']!,
      backup['nonce']!,
      backup['blob']!,
    );
    final restored = KeyPair(
      publicKey: bobKeys.publicKey,
      secretKey: crypto.sodium.secureCopy(Uint8List.fromList(restoredBytes)),
    );

    expect(crypto.isKeyPair(restored.publicKey, restored.secretKey), isTrue);
    expect(
      (await cipherFor(bob, restored).decrypt(message))!.text,
      'before the new phone',
    );
    await expectLater(
      backups.restoreBackup(
        '000000',
        backup['salt']!,
        backup['nonce']!,
        backup['blob']!,
      ),
      throwsA(anything),
    );
  });
}
