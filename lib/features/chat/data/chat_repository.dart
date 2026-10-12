import 'package:dio/dio.dart';
import 'package:genie/features/chat/models/chat_models.dart';
import 'package:genie/features/chat/models/chat_participant.dart';

/// API access to conversations and message history. Everything it returns
/// is still encrypted.
class ChatRepository {
  final Dio dio;

  ChatRepository({required this.dio});

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

  Map<String, dynamic> _asJson(dynamic json) =>
      Map<String, dynamic>.from(json as Map);
}
