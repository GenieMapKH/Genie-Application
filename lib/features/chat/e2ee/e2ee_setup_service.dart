import 'dart:convert';

import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/features/chat/data/chat_backup_repository.dart';
import 'package:tilomnov/features/chat/e2ee/backup/backup_service.dart';
import 'package:tilomnov/features/chat/e2ee/backup/key_backup_vault.dart';
import 'package:tilomnov/features/chat/e2ee/keys/key_service.dart';
import 'package:tilomnov/features/chat/e2ee/backup/pin_check.dart';

/// How [E2eeSetupService.initialize] ended. The UI turns this into a message.
enum E2eeSetupResult {
  ready,

  /// The account has no chat PIN yet: one is created first.
  pinNotSet,

  /// The chats are still locked with the account password: they are moved
  /// to a PIN first.
  lockedWithPassword,

  /// The PIN is needed on this device and the user closed the prompt.
  cancelled,

  /// Too many wrong PINs: the backup is locked for a while.
  rateLimited,
  failed,
}

/// Whether the account has its chat PIN. See [E2eeSetupService.pinStatus].
enum ChatPinStatus {
  set,
  notSet,

  /// Locked with the account password, as chats were for a short while:
  /// moved to a PIN with `PasswordLockMigration`.
  lockedWithPassword,

  /// The server could not be asked. Nothing is decided on a guess.
  unknown,
}

enum CreatePinResult {
  created,

  /// The account has a PIN already, e.g. set on another device just now.
  alreadySet,
  failed,
}

/// Makes end-to-end encryption ready on this device. Contains no UI.
///
/// Every account protects its chat keys with a 6-digit chat PIN, created
/// right after it first signs in ([createPin]). A device without the keys
/// gets them back from the server with that PIN ([initialize]).
class E2eeSetupService {
  final KeyService keyService;
  final BackupService backupService;
  final ChatBackupRepository backupRepository;

  late final KeyBackupVault _vault = KeyBackupVault(
    backupService: backupService,
    backupRepository: backupRepository,
  );

  /// The setup in progress. The quiet one at sign-in, the PIN being created
  /// and one started by a chat screen run one after the other, or two of
  /// them could make keys.
  Future<void> _running = Future.value();

  E2eeSetupService({
    required this.keyService,
    required this.backupService,
    required this.backupRepository,
  });

  /// Without [askPin] nothing is asked: keys behind the PIN are reported as
  /// [E2eeSetupResult.cancelled].
  Future<E2eeSetupResult> initialize(String userId, {PinPrompt? askPin}) {
    return _serialized(() => _initialize(userId, askPin));
  }

  /// Whether the account has its chat PIN. Asks the server.
  Future<ChatPinStatus> pinStatus() async {
    try {
      final backup = await backupRepository.fetchBackup();
      if (backup == null) return ChatPinStatus.notSet;
      return backup.lock == BackupLock.password
          ? ChatPinStatus.lockedWithPassword
          : ChatPinStatus.set;
    } catch (e, stackTrace) {
      AppLogger.error('Could not check the chat PIN', e, stackTrace);
      return ChatPinStatus.unknown;
    }
  }

  /// The account's first chat PIN. It protects the keys this device holds,
  /// or new ones when the account's keys are not here (they were never
  /// backed up, so no device here could read the earlier messages).
  Future<CreatePinResult> createPin(String userId, String pin) {
    return _serialized(() async {
      try {
        if (await _holdsCurrentKeys(userId)) {
          final keyPair = (await keyService.getIdentityKeyPair(userId))!;
          await _vault.save(pin, keyPair.secretKey.extractBytes());
        } else {
          final keyPair = keyService.cryptoService.generateKeyPair();
          await backupRepository.resetKeys(
            publicKey: base64Encode(keyPair.publicKey),
            backup: await _vault.seal(pin, keyPair.secretKey.extractBytes()),
          );
          // Kept only once the server took it.
          await keyService.saveIdentityKeyPair(userId, keyPair);
        }
        return CreatePinResult.created;
      } on WrongPinException {
        // The server wants the PIN of a backup that exists already.
        return CreatePinResult.alreadySet;
      } catch (e, stackTrace) {
        AppLogger.error('Could not create the chat PIN', e, stackTrace);
        return CreatePinResult.failed;
      }
    });
  }

  Future<T> _serialized<T>(Future<T> Function() step) {
    final result = _running.then((_) => step());
    // Only the queue ignores a failed step: [result] still carries it to
    // the caller, and the next step must run anyway.
    _running = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<E2eeSetupResult> _initialize(String userId, PinPrompt? askPin) async {
    try {
      final hasKeys = await _hasKeys(userId);
      if (hasKeys && await keyService.publishPublicKeyIfMissing(userId)) {
        return E2eeSetupResult.ready;
      }

      // No keys here, or the server lists other keys for the account.
      final backup = await backupRepository.fetchBackup();
      if (backup == null) {
        // A brand-new account gets keys at once, so others can message it;
        // the chat PIN created next protects them.
        if (askPin == null && !hasKeys) {
          await keyService.createAndPublishKeyPair(userId);
          return E2eeSetupResult.ready;
        }
        return E2eeSetupResult.pinNotSet;
      }
      if (backup.lock == BackupLock.password) {
        return E2eeSetupResult.lockedWithPassword;
      }
      if (askPin == null) return E2eeSetupResult.cancelled;
      return await _restoreWithPin(userId, backup, askPin);
    } on BackupRateLimitedException {
      return E2eeSetupResult.rateLimited;
    } catch (e, stackTrace) {
      AppLogger.error('E2EE setup failed', e, stackTrace);
      return E2eeSetupResult.failed;
    }
  }

  /// Asks for the PIN until the server releases the backup with it, or the
  /// user gives up. Each wrong PIN is shown while the prompt stays open.
  Future<E2eeSetupResult> _restoreWithPin(
    String userId,
    StoredBackup backup,
    PinPrompt askPin,
  ) async {
    PinCheckResult? last;
    final restored = await askPin((pin) async {
      last = await checkPin(() async {
        final opened = await _vault.open(pin, backup);
        await keyService.restoreIdentityKeyPair(
          userId,
          publicKey: base64Decode(
            await backupRepository.fetchPublicKey(userId),
          ),
          secretKeyBytes: opened.privateKey,
        );
      });
      return last!;
    });
    if (restored) return E2eeSetupResult.ready;
    return last is PinLockedOut
        ? E2eeSetupResult.rateLimited
        : E2eeSetupResult.cancelled;
  }

  Future<bool> _hasKeys(String userId) async =>
      await keyService.hasLocalKeyPair(userId) ||
      await keyService.adoptLegacyKeyPair(userId);

  Future<bool> _holdsCurrentKeys(String userId) async =>
      await _hasKeys(userId) &&
      await keyService.publishPublicKeyIfMissing(userId);
}
