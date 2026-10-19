import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/features/chat/models/chat_composer_mode.dart';
import 'package:genie/features/chat/providers/active_chat_state.dart';

/// Whether the open conversation's message bar is replying to or editing a
/// message. Null while it writes a new one.
final chatComposerProvider = StateProvider.autoDispose
    .family<ChatComposerMode?, ChatParticipants>((ref, chat) => null);
