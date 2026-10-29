import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Starts a voice call with the other person of a conversation.
typedef ChatCallStarter =
    Future<void> Function(String participantId, String participantName);

/// Calls belong to their own feature, which itself uses the chat
/// connection, so chat does not import it: the app supplies this at
/// start-up (see `lib/app/navigation`). Null (in tests, or before it is
/// wired) hides the call button.
final chatCallStarterProvider = Provider<ChatCallStarter?>((ref) => null);
