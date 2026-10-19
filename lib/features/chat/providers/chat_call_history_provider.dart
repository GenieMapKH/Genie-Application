import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/chat/data/chat_repository.dart';
import 'package:genie/features/chat/data/chat_socket_service.dart';
import 'package:genie/features/chat/models/chat_call_entry.dart';
import 'package:genie/features/chat/providers/active_chat_state.dart';
import 'package:genie/features/chat/providers/chat_service_providers.dart';

/// The calls of one open conversation, to show among its messages. Loaded
/// when the conversation opens, and again whenever a call ends (the server
/// has recorded it by then) or the connection comes back.
class ChatCallHistoryNotifier extends StateNotifier<List<ChatCallEntry>> {
  final String participantId;
  final ChatRepository repository;
  final ChatSocketService socketService;

  final _subscriptions = <StreamSubscription<void>>[];

  ChatCallHistoryNotifier({
    required this.participantId,
    required this.repository,
    required this.socketService,
  }) : super(const []) {
    _subscriptions
      ..add(
        socketService.onCallEvent
            .where((event) => event.event == 'call:ended')
            .listen((_) => refresh()),
      )
      ..add(socketService.onConnected.listen((_) => refresh()));
    refresh();
  }

  Future<void> refresh() async {
    try {
      final calls = await repository.fetchCallHistory(participantId);
      if (mounted) state = calls;
    } catch (e, stackTrace) {
      // The conversation is fine without its calls; they come back with the
      // next refresh.
      AppLogger.error('Call history not loaded', e, stackTrace);
    }
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}

final chatCallHistoryProvider = StateNotifierProvider.autoDispose
    .family<ChatCallHistoryNotifier, List<ChatCallEntry>, ChatParticipants>((
      ref,
      chat,
    ) {
      return ChatCallHistoryNotifier(
        participantId: chat.participantId,
        repository: ref.watch(chatRepositoryProvider),
        socketService: ref.watch(chatSocketServiceProvider),
      );
    });
