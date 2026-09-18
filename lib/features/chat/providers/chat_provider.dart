import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/services/chat_socket_service.dart';
import 'package:genie/services/crypto_service.dart';
import 'package:genie/services/key_service.dart';
import 'package:dio/dio.dart';
import 'package:genie/core/network/api_client.dart';
import 'package:genie/services/backup_service.dart';
import 'package:genie/services/e2ee_init_service.dart';
import 'package:genie/features/chat/models/chat_models.dart';

final cryptoServiceProvider = Provider<CryptoService>((ref) {
  throw UnimplementedError('Initialize CryptoService in main.dart');
});
final keyServiceProvider = Provider((ref) => KeyService(
  cryptoService: ref.watch(cryptoServiceProvider),
  dio: createApiClient(),
));

final backupServiceProvider = Provider((ref) => BackupService());

final e2eeInitServiceProvider = Provider((ref) => E2EEInitService(
  keyService: ref.watch(keyServiceProvider),
  backupService: ref.watch(backupServiceProvider),
  dio: createApiClient(),
  chatSocketService: ref.watch(chatSocketServiceProvider),
));

final chatSocketServiceProvider = Provider((ref) {
  final service = ChatSocketService(
    cryptoService: ref.watch(cryptoServiceProvider),
    keyService: ref.watch(keyServiceProvider),
    dio: createApiClient(),
  );
  return service;
});

class ConversationsNotifier extends StateNotifier<AsyncValue<List<ChatConversation>>> {
  final Dio dio;
  final ChatSocketService socketService;

  ConversationsNotifier({required this.dio, required this.socketService})
      : super(const AsyncValue.loading()) {
    fetchConversations();
    socketService.onMessageReceived.listen((_) {
      fetchConversations();
    });
  }

  Future<void> fetchConversations() async {
    try {
      final response = await dio.get('/chat/conversations');
      final List data = response.data;
      final conversations = data.map((json) => ChatConversation.fromJson(json)).toList();
      state = AsyncValue.data(conversations);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsRead(String participantId) async {
    try {
      await dio.post('/chat/messages/$participantId/read');
      if (state.hasValue) {
        final current = state.value!;
        final updated = current.map((conv) {
          if (conv.participantId == participantId) {
            return conv.copyWith(unreadCount: 0);
          }
          return conv;
        }).toList();
        state = AsyncValue.data(updated);
      }
    } catch (e) {
      print('Failed to mark messages as read: $e');
    }
  }
}

final conversationsProvider =
    StateNotifierProvider<ConversationsNotifier, AsyncValue<List<ChatConversation>>>((ref) {
  return ConversationsNotifier(
    dio: createApiClient(),
    socketService: ref.watch(chatSocketServiceProvider),
  );
});

final unreadCountProvider = Provider<int>((ref) {
  final convsState = ref.watch(conversationsProvider);
  return convsState.maybeWhen(
    data: (conversations) => conversations.fold(0, (sum, item) => sum + item.unreadCount),
    orElse: () => 0,
  );
});

class ActiveChatState {
  final String participantId;
  final String participantName;
  final List<ChatMessage> messages;

  ActiveChatState({
    required this.participantId,
    required this.participantName,
    this.messages = const [],
  });

  ActiveChatState copyWith({
    String? participantId,
    String? participantName,
    List<ChatMessage>? messages,
  }) {
    return ActiveChatState(
      participantId: participantId ?? this.participantId,
      participantName: participantName ?? this.participantName,
      messages: messages ?? this.messages,
    );
  }
}

class ChatNotifier extends StateNotifier<ActiveChatState?> {
  final ChatSocketService socketService;
  final Dio dio;
  final Ref ref;

  ChatNotifier(this.socketService, this.dio, this.ref) : super(null) {
    socketService.onMessageReceived.listen((message) {
      if (state != null && 
         (message.senderId == state!.participantId || message.recipientId == state!.participantId)) {
        state = state!.copyWith(
          messages: [...state!.messages, message],
        );
      }
    });
  }

  Future<void> setActiveChat(String participantId, String participantName) async {
    state = ActiveChatState(
      participantId: participantId,
      participantName: participantName,
      messages: [],
    );

    // 1. Mark as read
    ref.read(conversationsProvider.notifier).markAsRead(participantId);

    // 2. Load history
    try {
      final response = await dio.get('/chat/messages/$participantId');
      final List rawMessages = response.data;
      final List<ChatMessage> loaded = [];

      for (var raw in rawMessages) {
        final decrypted = await socketService.decryptMessagePayload(raw);
        if (decrypted != null) {
          loaded.add(decrypted);
        } else {
          loaded.add(ChatMessage(
            id: raw['id'],
            senderId: raw['senderId'],
            recipientId: raw['recipientId'],
            text: '[Message]',
            createdAt: DateTime.parse(raw['createdAt']),
          ));
        }
      }

      if (state?.participantId == participantId) {
        state = state!.copyWith(messages: loaded);
      }
    } catch (e) {
      print('Failed to load chat history: $e');
    }
  }

  void clearActiveChat() {
    state = null;
  }

  Future<void> sendMessage(String text) async {
    if (state == null) return;
    
    final participantId = state!.participantId;
    
    final tempMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'me',
      recipientId: participantId,
      text: text,
      createdAt: DateTime.now(),
    );

    state = state!.copyWith(
      messages: [...state!.messages, tempMsg],
    );

    await socketService.sendMessage(participantId, text);
    ref.read(conversationsProvider.notifier).fetchConversations();
  }
}

final activeChatProvider = StateNotifierProvider<ChatNotifier, ActiveChatState?>((ref) {
  return ChatNotifier(
    ref.watch(chatSocketServiceProvider),
    createApiClient(),
    ref,
  );
});
