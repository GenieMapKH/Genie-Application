import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:genie/core/network/api_cache_manager.dart';
import 'package:genie/features/chat/models/chat_call_entry.dart';
import 'package:genie/features/chat/models/chat_models.dart';
import 'package:genie/features/chat/models/chat_participant.dart';

/// API access to conversations and message history. Everything it returns
/// is still encrypted.
class ChatRepository {
  final Dio dio;

  /// For signed storage links. They carry their own permission, so this
  /// client sends no session token to the storage host.
  final Dio storageDio;

  ChatRepository({required this.dio, Dio? storageDio})
    : storageDio = storageDio ?? Dio();

  /// The main list, or with [archived] the archive.
  Future<List<ChatConversation>> fetchConversations({
    bool archived = false,
  }) async {
    final response = await dio.get(
      '/chat/conversations',
      queryParameters: {if (archived) 'list': 'archived'},
    );
    return (response.data as List)
        .map((json) => ChatConversation.fromJson(_asJson(json)))
        .toList();
  }

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
