import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/core/network/api_version_interceptor.dart';
import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';
import 'package:tilomnov/features/chat/data/chat_access_token.dart';
import 'package:tilomnov/features/chat/data/chat_attachment_service.dart';
import 'package:tilomnov/features/chat/data/chat_attachment_store.dart';
import 'package:tilomnov/features/chat/data/chat_repository.dart';
import 'package:tilomnov/features/chat/data/chat_socket_service.dart';
import 'package:tilomnov/features/chat/data/chat_crypto.dart';
import 'package:tilomnov/features/chat/data/message_codec.dart';
import 'package:tilomnov/features/profile/presentation/view_models/user_providers.dart';

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
    onApiVersionRetired: () =>
        ref.read(apiVersionRetiredProvider.notifier).state = true,
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

final messageCodecProvider = Provider.family<MessageCodec, String>(
  (ref, userId) => MessageCodec(userId: userId),
);
