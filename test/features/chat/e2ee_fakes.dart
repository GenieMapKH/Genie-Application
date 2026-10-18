import 'dart:async';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' show SecretKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/chat/data/chat_backup_repository.dart';
import 'package:genie/features/chat/e2ee/backup/backup_service.dart';
import 'package:genie/features/chat/e2ee/keys/crypto_service.dart';
import 'package:genie/features/chat/e2ee/keys/key_service.dart';
import 'package:genie/features/chat/e2ee/backup/pin_check.dart';
import 'package:sodium_libs/sodium_libs.dart';

class _FakeSecureKey extends Fake implements SecureKey {
  @override
  Uint8List extractBytes() => Uint8List.fromList([1, 2, 3]);
}

KeyPair _fakeKeyPair() =>
    KeyPair(publicKey: Uint8List.fromList([9]), secretKey: _FakeSecureKey());

class _FakeCryptoService extends Fake implements CryptoService {
  @override
  KeyPair generateKeyPair() => _fakeKeyPair();
}

class FakeKeyService extends Fake implements KeyService {
  bool hasLocal = false;
  bool hasLegacy = false;
  bool restoredKeyMatches = true;
  int savedKeyPairs = 0;
  int publicKeyUploads = 0;

  /// New pairs made and published in place of the account's key.
  int publishedNewPairs = 0;
  Object? publishError;

  /// Holds a new pair back until completed, to see setups overlap.
  Completer<void>? publishGate;

  /// False once the account's keys were replaced on another device.
  bool serverAcceptsLocalKey = true;

  @override
  final CryptoService cryptoService = _FakeCryptoService();

  @override
  Future<bool> hasLocalKeyPair(String userId) async => hasLocal;

  @override
  Future<KeyPair?> getIdentityKeyPair(String userId) async =>
      hasLocal ? _fakeKeyPair() : null;

  @override
  Future<bool> adoptLegacyKeyPair(String userId) async => hasLegacy;

  @override
  Future<void> saveIdentityKeyPair(String userId, KeyPair keyPair) async {
    savedKeyPairs++;
    hasLocal = true;
  }

  @override
  Future<void> restoreIdentityKeyPair(
    String userId, {
    required Uint8List publicKey,
    required List<int> secretKeyBytes,
  }) async {
    if (!restoredKeyMatches) throw StateError('key mismatch');
    savedKeyPairs++;
    hasLocal = true;
  }

  @override
  Future<bool> publishPublicKeyIfMissing(String userId) async {
    publicKeyUploads++;
    return serverAcceptsLocalKey;
  }

  @override
  Future<KeyPair> createAndPublishKeyPair(String userId) async {
    await publishGate?.future;
    if (publishError != null) throw publishError!;
    publishedNewPairs++;
    hasLocal = true;
    serverAcceptsLocalKey = true;
    return _fakeKeyPair();
  }
}

class FakeBackupService extends Fake implements BackupService {
  bool pinIsCorrect = true;

  @override
  Future<Map<String, String>> createBackup(
    String pin,
    List<int> privateKeyBytes,
  ) async => {
    'blob': 'new-blob',
    'salt': 'new-salt',
    'nonce': 'new-nonce',
    'verifier': 'new-verifier',
  };

  @override
  Future<BackupKeys> deriveKeys(String pin, String saltB64) async =>
      BackupKeys(encryptionKey: SecretKey([0]), verifier: 'proof-of-$pin');

  @override
  Future<List<int>> openBackup(
    BackupKeys keys,
    String nonceB64,
    String blobB64,
  ) async => [1, 2, 3];

  @override
  Future<List<int>> restoreLegacyBackup(
    String pin,
    String saltB64,
    String nonceB64,
    String blobB64,
  ) async {
    if (!pinIsCorrect) throw Exception('MAC check failed');
    return [1, 2, 3];
  }
}

class FakeBackupRepository extends Fake implements ChatBackupRepository {
  StoredBackup? stored;
  Object? fetchError;
  Object? unlockError;
  Object? saveError;
  Object? resetError;
  int fetches = 0;
  final List<String> unlockTries = [];
  final List<EncryptedBackup> saved = [];

  /// What was sent with each save or reset to show the backup may be
  /// replaced: the current PIN's proof, or a password proof.
  final List<Map<String, String>?> proofs = [];

  /// The public key the server lists for the account.
  String serverPublicKey = 'CQ=='; // base64 of [9], the fake key pair
  final List<String> resetPublicKeys = [];

  /// When set, only this PIN or password opens [stored]; a wrong one is
  /// answered with [attemptsLeft].
  String? opensWith;
  int? attemptsLeft;

  /// The account's password, as the sign-in server knows it.
  String accountPassword = 'right-password';
  int passwordProofs = 0;

  @override
  Future<StoredBackup?> fetchBackup() async {
    fetches++;
    if (fetchError != null) throw fetchError!;
    return stored;
  }

  @override
  Future<SealedKey> unlockBackup(String verifier) async {
    unlockTries.add(verifier);
    if (unlockError != null) throw unlockError!;
    final secret = opensWith;
    if (secret != null && verifier != 'proof-of-$secret') {
      throw WrongPinException(attemptsLeft: attemptsLeft);
    }
    return const SealedKey(blob: 'b', nonce: 'n');
  }

  @override
  Future<String> provePassword(String password) async {
    if (password != accountPassword) throw const WrongPasswordException();
    passwordProofs++;
    return 'password-proof';
  }

  @override
  Future<void> saveBackup(
    EncryptedBackup backup, {
    BackupOwnerProof? ownerProof,
  }) async {
    if (saveError != null) throw saveError!;
    saved.add(backup);
    proofs.add(ownerProof?.toJson());
  }

  @override
  Future<void> resetKeys({
    required String publicKey,
    required EncryptedBackup backup,
    BackupOwnerProof? ownerProof,
  }) async {
    if (resetError != null) throw resetError!;
    resetPublicKeys.add(publicKey);
    saved.add(backup);
    proofs.add(ownerProof?.toJson());
  }

  @override
  Future<String> fetchPublicKey(String userId) async => serverPublicKey;
}

/// A PIN prompt where the user types [pins] in turn, each checked while the
/// prompt stays open, until one is accepted or none are left (giving up).
/// What each check answered is added to [seen].
PinPrompt typing(List<String> pins, {List<PinCheckResult>? seen}) {
  return (check) async {
    for (final pin in pins) {
      final result = await check(pin);
      seen?.add(result);
      if (result is PinAccepted) return true;
    }
    return false;
  };
}

Future<bool> neverAsked(PinCheck check) async => fail('must not ask');
