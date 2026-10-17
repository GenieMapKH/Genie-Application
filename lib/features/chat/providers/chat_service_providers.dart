import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/auth/data/repositories/auth_repository.dart';
import 'package:genie/features/chat/data/chat_access_token.dart';
import 'package:genie/features/chat/data/chat_attachment_service.dart';
import 'package:genie/features/chat/data/chat_backup_repository.dart';
import 'package:genie/features/chat/data/chat_repository.dart';
import 'package:genie/features/chat/data/chat_socket_service.dart';
import 'package:genie/features/chat/e2ee/backup_service.dart';
import 'package:genie/features/chat/e2ee/crypto_service.dart';
import 'package:genie/features/chat/e2ee/e2ee_key_manager.dart';
import 'package:genie/features/chat/e2ee/e2ee_setup_service.dart';
import 'package:genie/features/chat/e2ee/key_service.dart';
import 'package:genie/features/chat/e2ee/message_cipher.dart';
import 'package:genie/features/chat/e2ee/peer_key_store.dart';
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

/// Opened files are kept in memory for the signed-in user only, so the
/// service is rebuilt (and that memory dropped) when the user changes.
final chatAttachmentServiceProvider = Provider<ChatAttachmentService>((ref) {
  ref.watch(currentUserIdProvider);
  return ChatAttachmentService(
    repository: ref.watch(chatRepositoryProvider),
    cryptoService: ref.watch(cryptoServiceProvider),
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

final e2eeKeyManagerProvider = Provider(
  (ref) => E2eeKeyManager(
    keyService: ref.watch(keyServiceProvider),
    backupService: ref.watch(backupServiceProvider),
    backupRepository: ref.watch(chatBackupRepositoryProvider),
  ),
);
