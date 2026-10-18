import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/auth/data/repositories/auth_repository.dart';
import 'package:genie/features/chat/data/chat_access_token.dart';
import 'package:genie/features/chat/data/chat_attachment_service.dart';
import 'package:genie/features/chat/data/chat_attachment_store.dart';
import 'package:genie/features/chat/data/chat_backup_repository.dart';
import 'package:genie/features/chat/data/chat_repository.dart';
import 'package:genie/features/chat/data/chat_socket_service.dart';
import 'package:genie/features/chat/e2ee/backup/backup_service.dart';
import 'package:genie/features/chat/e2ee/keys/crypto_service.dart';
import 'package:genie/features/chat/e2ee/e2ee_key_manager.dart';
import 'package:genie/features/chat/e2ee/e2ee_setup_service.dart';
import 'package:genie/features/chat/e2ee/keys/key_service.dart';
import 'package:genie/features/chat/e2ee/keys/message_cipher.dart';
import 'package:genie/features/chat/e2ee/backup/password_lock_migration.dart';
import 'package:genie/features/chat/e2ee/keys/peer_key_store.dart';
import 'package:genie/features/profile/presentation/view_models/user_providers.dart';

/// Overridden in `main.dart` once libsodium has been initialised.
final cryptoServiceProvider = Provider<CryptoService>((ref) {
  throw UnimplementedError('Initialize CryptoService in main.dart');
});

/// Id of the signed-in user, or null for a guest. Everything chat keeps per
/// user (connection, keys, conversations) is rebuilt when it changes.
final currentUserIdProvider = Provider<String?>((ref) {
  final profile = ref.watch(userProfileProvider);
  return profile.hasError ? null : profile.valueOrNull?.id;
});

final keyServiceProvider = Provider(
  (ref) => KeyService(
    cryptoService: ref.watch(cryptoServiceProvider),
    dio: ref.watch(apiClientProvider),
  ),
);

final backupServiceProvider = Provider((ref) => BackupService());

final chatBackupRepositoryProvider = Provider(
  (ref) => ChatBackupRepository(dio: ref.watch(apiClientProvider)),
);

final chatRepositoryProvider = Provider(
  (ref) => ChatRepository(dio: ref.watch(apiClientProvider)),
);

/// One store for the app's lifetime (two would share one database). When a
/// different user signs in, the previous user's files are removed: they could
/// not be opened without that user's messages, but they are theirs.
final chatAttachmentStoreProvider = Provider<ChatAttachmentStore>((ref) {
  final store = ChatAttachmentStore();
  // Signing out passes through "nobody", so the last real user is compared.
  String? lastUserId;
  ref.listen<String?>(currentUserIdProvider, (_, userId) {
    if (userId == null) return;
    if (lastUserId != null && lastUserId != userId) store.clear();
    lastUserId = userId;
  }, fireImmediately: true);
  return store;
});

/// Opened files are kept in memory for the signed-in user only, so the
/// service is rebuilt (and that memory dropped) when the user changes.
final chatAttachmentServiceProvider = Provider<ChatAttachmentService>((ref) {
  ref.watch(currentUserIdProvider);
  return ChatAttachmentService(
    repository: ref.watch(chatRepositoryProvider),
    cryptoService: ref.watch(cryptoServiceProvider),
    store: ref.watch(chatAttachmentStoreProvider),
  );
});

/// One connection per signed-in user, open for as long as they are signed
/// in so new messages and unread counts arrive without opening a chat.
final chatSocketServiceProvider = Provider<ChatSocketService>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final service = ChatSocketService(
    readAccessToken: ChatAccessToken(dio: ref.watch(apiClientProvider)).read,
  );
  ref.onDispose(service.dispose);
  if (userId != null) {
    service.connect().catchError((Object e) {
      AppLogger.error('Chat socket could not connect', e);
      return false;
    });
  }
  return service;
});

final messageCipherProvider = Provider.family<MessageCipher, String>(
  (ref, userId) => MessageCipher(
    userId: userId,
    cryptoService: ref.watch(cryptoServiceProvider),
    keyService: ref.watch(keyServiceProvider),
    keyRepository: ref.watch(chatBackupRepositoryProvider),
    trustedKeys: PeerKeyStore(userId: userId),
  ),
);

final e2eeSetupServiceProvider = Provider(
  (ref) => E2eeSetupService(
    keyService: ref.watch(keyServiceProvider),
    backupService: ref.watch(backupServiceProvider),
    backupRepository: ref.watch(chatBackupRepositoryProvider),
  ),
);

/// Gets chat keys ready as soon as someone signs in, without asking
/// anything, so others can message them before they ever open a chat. Kept
/// alive by the app shell. An account with a chat PIN on a device without
/// its keys waits for a chat screen, which asks for the PIN.
final chatKeysQuietSetupProvider = FutureProvider<E2eeSetupResult?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref.watch(e2eeSetupServiceProvider).initialize(userId);
});

/// Whether the signed-in user still has to create their chat PIN. Asked once
/// per sign-in; null for a guest. Refreshed once a PIN is created.
final chatPinStatusProvider = FutureProvider<ChatPinStatus?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref.watch(e2eeSetupServiceProvider).pinStatus();
});

final e2eeKeyManagerProvider = Provider(
  (ref) => E2eeKeyManager(
    keyService: ref.watch(keyServiceProvider),
    backupService: ref.watch(backupServiceProvider),
    backupRepository: ref.watch(chatBackupRepositoryProvider),
  ),
);

/// A fresh migration for each screen that moves [userId]'s chats from the
/// account password to a chat PIN.
final passwordLockMigrationProvider = Provider.autoDispose
    .family<PasswordLockMigration, String>(
      (ref, userId) => PasswordLockMigration(
        userId: userId,
        keyService: ref.watch(keyServiceProvider),
        backupService: ref.watch(backupServiceProvider),
        backupRepository: ref.watch(chatBackupRepositoryProvider),
        keyManager: ref.watch(e2eeKeyManagerProvider),
      ),
    );
