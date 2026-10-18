import 'package:dio/dio.dart';
import 'package:genie/core/errors/app_exceptions.dart';

/// What the identity key backup is locked with. Every account protects its
/// chats with a 6-digit chat PIN. [password] is only for backups made while
/// chats were locked with the account password: they are moved to a PIN the
/// next time the account is used.
enum BackupLock {
  pin,
  password;

  /// As the server names it (`protectedBy`); anything unknown is a PIN.
  static BackupLock fromName(Object? name) =>
      name == 'password' ? BackupLock.password : BackupLock.pin;
}

/// The identity private key, encrypted on the device with a key made from the
/// user's PIN. [verifier] lets the server check the PIN without knowing it.
class EncryptedBackup {
  final String blob;
  final String salt;
  final String nonce;
  final String verifier;

  const EncryptedBackup({
    required this.blob,
    required this.salt,
    required this.nonce,
    required this.verifier,
  });
}

/// The encrypted key itself, as the server releases it.
class SealedKey {
  final String blob;
  final String nonce;

  const SealedKey({required this.blob, required this.nonce});
}

/// What the server tells a signed-in device before the PIN is proven.
class StoredBackup {
  final String salt;

  /// Whether to ask for the backup PIN or the account password.
  final BackupLock lock;

  /// Only for a backup made before the server counted PIN tries: it is still
  /// handed out whole, and replaced the first time it is opened.
  final SealedKey? legacyKey;

  const StoredBackup({
    required this.salt,
    this.legacyKey,
    this.lock = BackupLock.pin,
  });
}

/// Thrown while the server refuses backup requests: too many lookups, or the
/// backup is locked after too many wrong PINs. [retryAfter] is how long the
/// lock lasts, when the server says.
class BackupRateLimitedException extends AppException {
  final Duration? retryAfter;

  const BackupRateLimitedException({this.retryAfter})
    : super('Too many backup attempts', code: '429');
}

/// How the owner shows that an existing key backup is theirs to replace.
class BackupOwnerProof {
  final String? _currentVerifier;
  final String? _passwordProofToken;

  /// The proof of the backup's current PIN (see `BackupKeys.verifier`).
  const BackupOwnerProof.pin(String verifier)
    : _currentVerifier = verifier,
      _passwordProofToken = null;

  /// For a forgotten PIN: the token the server gives after checking the
  /// account password (`AccountRepository.requestPasswordProof`).
  const BackupOwnerProof.password(String proofToken)
    : _currentVerifier = null,
      _passwordProofToken = proofToken;

  Map<String, String> toJson() => {
    'currentBackupVerifier': ?_currentVerifier,
    'passwordProofToken': ?_passwordProofToken,
  };
}

/// Thrown when the server rejects the PIN (the try has been counted), or
/// the [BackupOwnerProof] sent to replace a backup. [attemptsLeft] is how
/// many more wrong PINs lock the backup, when the server says.
class WrongPinException extends AppException {
  final int? attemptsLeft;

  const WrongPinException({this.attemptsLeft})
    : super('Wrong PIN', code: '403');
}

/// The account password typed to open the chat keys is not the account's.
class WrongPasswordException extends AppException {
  const WrongPasswordException() : super('Wrong password', code: '403');
}

/// API access for the E2EE key backup and public keys.
class ChatBackupRepository {
  final Dio dio;

  ChatBackupRepository({required this.dio});

  /// The stored backup, or null when the user has never created one.
  Future<StoredBackup?> fetchBackup() async {
    try {
      final response = await dio.get('/chat/backup');
      final data = response.data;
      final legacyBlob = data['backupBlob'] as String?;
      final legacyNonce = data['backupNonce'] as String?;
      return StoredBackup(
        salt: data['backupSalt'] as String,
        lock: BackupLock.fromName(data['protectedBy']),
        legacyKey: legacyBlob != null && legacyNonce != null
            ? SealedKey(blob: legacyBlob, nonce: legacyNonce)
            : null,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      _throwRefusal(e);
    }
  }

  /// Asks the server for the encrypted key. Each wrong [verifier] is counted,
  /// and after several the backup locks for a while.
  Future<SealedKey> unlockBackup(String verifier) async {
    try {
      final response = await dio.post(
        '/chat/backup/unlock',
        data: {'backupVerifier': verifier},
      );
      return SealedKey(
        blob: response.data['backupBlob'] as String,
        nonce: response.data['backupNonce'] as String,
      );
    } on DioException catch (e) {
      _throwRefusal(e);
    }
  }

  /// Stores [backup]. When it replaces an existing backup the server wants
  /// [ownerProof]: a wrong one throws [WrongPinException], and a wrong PIN
  /// is counted like a wrong unlock.
  Future<void> saveBackup(
    EncryptedBackup backup, {
    BackupOwnerProof? ownerProof,
  }) {
    return _replaceProtected(
      () => dio.post('/chat/backup', data: _body(backup, ownerProof)),
    );
  }

  /// Replaces the account's key pair: [publicKey] and the [backup] of its
  /// private key are swapped together. [ownerProof] as in [saveBackup].
  Future<void> resetKeys({
    required String publicKey,
    required EncryptedBackup backup,
    BackupOwnerProof? ownerProof,
  }) {
    return _replaceProtected(
      () => dio.post(
        '/chat/keys/reset',
        data: {..._body(backup, ownerProof), 'identityPublicKey': publicKey},
      ),
    );
  }

  /// A token, good for a few minutes, proving [password] is the account's.
  /// The chat server takes it in place of a forgotten PIN when a backup is
  /// replaced. Throws [WrongPasswordException] for another password and
  /// [BackupRateLimitedException] after too many.
  Future<String> provePassword(String password) async {
    try {
      final response = await dio.post(
        '/auth/account/password-proof',
        data: {'password': password},
      );
      return response.data['proofToken'] as String;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 403) throw const WrongPasswordException();
      if (status == 429) throw const BackupRateLimitedException();
      rethrow;
    }
  }

  Map<String, String> _body(EncryptedBackup backup, BackupOwnerProof? proof) {
    return {
      'backupBlob': backup.blob,
      'backupSalt': backup.salt,
      'backupNonce': backup.nonce,
      'backupVerifier': backup.verifier,
      'protectedBy': BackupLock.pin.name,
      ...?proof?.toJson(),
    };
  }

  Future<void> _replaceProtected(Future<void> Function() request) async {
    try {
      await request();
    } on DioException catch (e) {
      _throwRefusal(e);
    }
  }

  /// A wrong PIN (`403`) or a locked backup (`429`) as its exception, with
  /// what the server says about tries left or the wait; anything else as is.
  Never _throwRefusal(DioException e) {
    final body = e.response?.data;
    final details = body is Map ? body : const {};
    switch (e.response?.statusCode) {
      case 403:
        final left = details['attemptsLeft'];
        throw WrongPinException(attemptsLeft: left is int ? left : null);
      case 429:
        final seconds = details['retryAfterSeconds'];
        throw BackupRateLimitedException(
          retryAfter: seconds is int ? Duration(seconds: seconds) : null,
        );
    }
    Error.throwWithStackTrace(e, e.stackTrace);
  }

  /// Base64 public key of [userId] as stored on the server.
  Future<String> fetchPublicKey(String userId) async {
    final response = await dio.get('/chat/keys/$userId');
    return response.data['identityPublicKey'] as String;
  }
}
