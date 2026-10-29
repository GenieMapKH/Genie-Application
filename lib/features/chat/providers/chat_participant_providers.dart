import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/features/chat/models/chat_attachment.dart';
import 'package:tilomnov/features/chat/models/chat_participant.dart';
import 'package:tilomnov/features/chat/providers/active_chat_state.dart';
import 'package:tilomnov/features/chat/providers/chat_service_providers.dart';

/// Whether the given user is online, kept current while something watches.
final chatPresenceProvider = StreamProvider.autoDispose
    .family<ChatPresence, String>((ref, userId) {
      final socket = ref.watch(chatSocketServiceProvider);
      final updates = StreamController<ChatPresence>();

      Future<void> watch() async {
        try {
          final presence = await socket.watchPresence(userId);
          if (!updates.isClosed) updates.add(presence);
        } catch (e) {
          // Not connected yet: asked again when the connection is back.
          AppLogger.error('Could not read presence', e);
        }
      }

      final subscriptions = [
        socket.onPresence
            .where((presence) => presence.userId == userId)
            .listen(updates.add),
        // The server forgets who was watching when a connection ends.
        socket.onConnected.listen((_) => watch()),
      ];
      watch();

      ref.onDispose(() {
        for (final subscription in subscriptions) {
          subscription.cancel();
        }
        socket.unwatchPresence(userId);
        updates.close();
      });
      return updates.stream;
    });

/// Name, picture and join date of the person being chatted with.
final chatParticipantProfileProvider = FutureProvider.autoDispose
    .family<ChatParticipantProfile, String>((ref, userId) {
      return ref.watch(chatRepositoryProvider).fetchParticipantProfile(userId);
    });

/// The code two people compare to confirm nobody swapped their keys.
/// Null until both have keys this device knows.
final chatSafetyCodeProvider = FutureProvider.autoDispose
    .family<String?, ChatParticipants>((ref, chat) {
      return ref
          .watch(messageCipherProvider(chat.userId))
          .safetyCode(chat.participantId);
    });

/// A received file, downloaded and decrypted in memory.
final chatAttachmentBytesProvider = FutureProvider.autoDispose
    .family<Uint8List, ChatAttachment>((ref, attachment) {
      return ref.watch(chatAttachmentServiceProvider).open(attachment);
    });
