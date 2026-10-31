import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:tilomnov/core/network/api_cache_manager.dart';
import 'package:tilomnov/core/storage/kept_copy_store.dart';
import 'package:tilomnov/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tilomnov/features/chat/models/chat_call_entry.dart';
import 'package:tilomnov/features/chat/models/chat_models.dart';
import 'package:tilomnov/features/chat/models/chat_participant.dart';

/// One page of a conversation list, where the next one starts (null after
/// the last), and the unread messages in the whole list.
typedef ConversationPage = ({
  List<ChatConversation> items,
  String? nextCursor,
  int unreadTotal,
});

/// API access to conversations and message history. Everything it returns
/// is still encrypted.
class ChatRepository {
  final Dio dio;

  /// For signed storage links. They carry their own permission, so this
  /// client sends no session token to the storage host.
  final Dio storageDio;

  /// The first page of the main list, still encrypted as the server sent
  /// it, kept for the signed-in account by default ([keptFirstPage]).
  final KeptCopyStore _kept;
  static const _keptName = 'chat.conversations.first_page.v1';

  ChatRepository({
    required this.dio,
    Dio? storageDio,
    Future<String?> Function()? accountId,
  }) : storageDio = storageDio ?? Dio(),
       _kept = KeptCopyStore(account: accountId ?? AuthStorage.signedInUserId);

  /// Conversations per page of the chat list.
  static const conversationPageSize = 30;

  /// The most conversations one page holds (the server's limit).
  static const maxConversationPage = 100;

  /// [limit] conversations of the main list (or with [archived] the
  /// archive), most recent first, after [cursor] (from the start without).
  Future<ConversationPage> fetchConversationPage({
    bool archived = false,
    int limit = conversationPageSize,
    String? cursor,
  }) async {
    final response = await dio.get(
      '/chat/conversations',
      queryParameters: {
        if (archived) 'list': 'archived',
        'limit': limit,
        'cursor': ?cursor,
      },
    );
    final data = _asJson(response.data);
    if (!archived && cursor == null) await _kept.write(_keptName, data);
    return _conversationPageOf(data);
  }

  /// The first page of the main list as last read on this device, or null.
  Future<ConversationPage?> keptFirstPage() =>
      _kept.read(_keptName, parse: _conversationPageOf);

  ConversationPage _conversationPageOf(Map<String, dynamic> data) => (
    items: (data['items'] as List)
        .map((json) => ChatConversation.fromJson(_asJson(json)))
        .toList(),
    nextCursor: data['nextCursor'] as String?,
    unreadTotal: data['unreadTotal'] as int? ?? 0,
  );

  /// The newest messages exchanged with [participantId], oldest first.
  Future<List<EncryptedMessage>> fetchMessages(String participantId) async {
    final response = await dio.get('/chat/messages/$participantId');
    return (response.data as List)
        .map((json) => EncryptedMessage.fromJson(_asJson(json)))
        .toList();
  }

  /// The finished calls with [participantId], oldest first. Calls are not
  /// encrypted: the server only records who called whom and how it ended.
  Future<List<ChatCallEntry>> fetchCallHistory(String participantId) async {
    final response = await dio.get(
      '/chat/calls/history',
      queryParameters: {'with': participantId},
    );
    return (response.data as List)
        .map((json) => ChatCallEntry.fromJson(_asJson(json)))
        .toList();
  }

  Future<void> archiveConversation(String participantId) async {
    await dio.post('/chat/conversations/$participantId/archive');
  }

  Future<void> unarchiveConversation(String participantId) async {
    await dio.post('/chat/conversations/$participantId/unarchive');
  }

  /// For this user only, or with [forEveryone] for both people, permanently.
  Future<void> deleteConversation(
    String participantId, {
    required bool forEveryone,
  }) async {
    await dio.post(
      '/chat/conversations/$participantId/delete',
      data: {'forEveryone': forEveryone},
    );
  }

  /// Replaces the text of the user's own message with [ciphertext], sealed
  /// again on this device. Returns the message as stored. The server
  /// refuses (403) once an hour has passed since it was sent.
  Future<EncryptedMessage> editMessage(
    String messageId, {
    required String ciphertext,
    required String nonce,
  }) async {
    final response = await dio.post(
      '/chat/messages/$messageId/edit',
      data: {'ciphertext': ciphertext, 'nonce': nonce},
    );
    return EncryptedMessage.fromJson(_asJson(response.data));
  }

  /// Hides the message from this user, or with [forEveryone] (their own
  /// message) deletes it and the file at [attachmentPath] for both people.
  Future<void> deleteMessage(
    String messageId, {
    required bool forEveryone,
    String? attachmentPath,
  }) async {
    await dio.post(
      '/chat/messages/$messageId/delete',
      data: {
        'forEveryone': forEveryone,
        if (forEveryone) 'attachmentPath': ?attachmentPath,
      },
    );
  }

  Future<void> markAsRead(String participantId) async {
    await dio.post('/chat/messages/$participantId/read');
  }

  /// Name, picture and join date of the person being chatted with.
  Future<ChatParticipantProfile> fetchParticipantProfile(String userId) async {
    // Shown at the top of every chat; a name or picture a minute old is fine.
    final response = await dio.get(
      '/users/$userId',
      options: Options(
        extra: CacheInterceptor.freshFor(const Duration(minutes: 1)),
      ),
    );
    return ChatParticipantProfile.fromJson(_asJson(response.data));
  }

  /// Stores an already encrypted file for [recipientId] and returns where
  /// it was put.
  Future<String> uploadEncryptedFile(
    String recipientId,
    Uint8List encrypted,
  ) async {
    final response = await dio.post(
      '/chat/attachments',
      data: {'recipientId': recipientId},
    );
    final upload = _asJson(response.data);

    await storageDio.put<void>(
      upload['uploadUrl'] as String,
      data: Stream.fromIterable([encrypted]),
      options: Options(
        headers: {
          Headers.contentLengthHeader: encrypted.length,
          Headers.contentTypeHeader: 'application/octet-stream',
        },
      ),
    );
    return upload['path'] as String;
  }

  /// The encrypted file stored at [path]. Only the two people in the
  /// conversation are given access.
  Future<Uint8List> downloadEncryptedFile(String path) async {
    final link = await dio.get('/chat/attachments/$path');
    final response = await storageDio.get<List<int>>(
      _asJson(link.data)['url'] as String,
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data!);
  }

  Map<String, dynamic> _asJson(dynamic json) =>
      Map<String, dynamic>.from(json as Map);
}
