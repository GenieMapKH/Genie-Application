import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/features/chat/providers/active_chat_state.dart';

/// The id of the message the user tapped in the open conversation: its
/// time is shown above it, and when it is theirs, its delivery below.
/// Null while none is.
final chatTappedMessageProvider = StateProvider.autoDispose
    .family<String?, ChatParticipants>((ref, chat) => null);
