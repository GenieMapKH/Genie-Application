import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/services/chat_socket_service.dart';
import 'package:genie/services/crypto_service.dart';
import 'package:genie/services/key_service.dart';
import 'package:dio/dio.dart';
import 'package:genie/core/network/api_client.dart';
import 'package:genie/services/backup_service.dart';
import 'package:genie/services/e2ee_init_service.dart';

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
  // Auto-connect when provider is created? Better to connect during E2EE Init.
  return service;
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

  ChatNotifier(this.socketService) : super(null) {
    socketService.onMessageReceived.listen((message) {
      if (state != null && 
         (message.senderId == state!.participantId || message.recipientId == state!.participantId)) {
        state = state!.copyWith(
          messages: [...state!.messages, message],
        );
      }
    });
  }

  void setActiveChat(String participantId, String participantName) {
    // Note: We don't have local SQLite yet, so we start with an empty list for this session,
    // unless they were already synced in memory. For now, just reset the list.
    state = ActiveChatState(
      participantId: participantId,
      participantName: participantName,
      messages: [], // Ideally we would load from a local DB here
    );
  }

  void clearActiveChat() {
    state = null;
  }

  Future<void> sendMessage(String text) async {
    if (state == null) return;
    
    final participantId = state!.participantId;
    
    // Add the message optimistically to the UI
    final tempMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'me', // Represents the current user
      recipientId: participantId,
      text: text,
      createdAt: DateTime.now(),
    );

    state = state!.copyWith(
      messages: [...state!.messages, tempMsg],
    );

    await socketService.sendMessage(participantId, text);
  }
}

final activeChatProvider = StateNotifierProvider<ChatNotifier, ActiveChatState?>((ref) {
  return ChatNotifier(ref.watch(chatSocketServiceProvider));
});
