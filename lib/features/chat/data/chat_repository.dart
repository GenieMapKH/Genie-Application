import 'dart:typed_data';

import 'package:dio/dio.dart';
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

  Future<List<ChatConversation>> fetchConversations() async {
    final response = await dio.get('/chat/conversations');
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

  Future<void> markAsRead(String participantId) async {
    await dio.post('/chat/messages/$participantId/read');
  }

  /// Name, picture and join date of the person being chatted with.
  Future<ChatParticipantProfile> fetchParticipantProfile(String userId) async {
    final response = await dio.get('/users/$userId');
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
