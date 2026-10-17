import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Who to show, as far as the conversation knows them.
class ChatProfileTarget {
  final String userId;
  final String? name;
  final String? username;
  final String? avatarUrl;

  const ChatProfileTarget({
    required this.userId,
    this.name,
    this.username,
    this.avatarUrl,
  });
}

/// Opens the other person's profile from a conversation.
typedef ChatProfileOpener =
    Future<void> Function(BuildContext context, ChatProfileTarget target);

/// The profile page belongs to another feature, which itself opens chats, so
/// chat does not import it: the app supplies this at start-up (see
/// `lib/app/navigation`). Null (in tests, or before it is wired) keeps the
/// built-in participant sheet.
final chatProfileOpenerProvider = Provider<ChatProfileOpener?>((ref) => null);
