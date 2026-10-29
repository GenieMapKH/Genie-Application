import 'package:tilomnov/features/chat/models/chat_call_entry.dart';
import 'package:tilomnov/features/chat/models/chat_models.dart';

/// One line of a conversation: a message, or a call that took place.
sealed class ChatTimelineItem {
  const ChatTimelineItem();

  DateTime get time;

  /// Stable across rebuilds, so a list keeps its place.
  String get key;
}

class ChatMessageItem extends ChatTimelineItem {
  final ChatMessage message;
  const ChatMessageItem(this.message);

  @override
  DateTime get time => message.createdAt;

  @override
  String get key => message.id;
}

class ChatCallItem extends ChatTimelineItem {
  final ChatCallEntry call;
  const ChatCallItem(this.call);

  @override
  DateTime get time => call.createdAt;

  @override
  String get key => 'call:${call.id}';
}

/// Messages and calls in the order they happened, oldest first. Messages
/// keep the order they came in, and come before a call at the same moment.
List<ChatTimelineItem> mergeTimeline(
  List<ChatMessage> messages,
  List<ChatCallEntry> calls,
) {
  final items = <ChatTimelineItem>[
    for (final message in messages) ChatMessageItem(message),
    for (final call in calls) ChatCallItem(call),
  ];
  // Stable: Dart's List.sort is not, so the position breaks ties.
  final order = {for (var i = 0; i < items.length; i++) items[i]: i};
  return items..sort((a, b) {
    final byTime = a.time.compareTo(b.time);
    return byTime != 0 ? byTime : order[a]!.compareTo(order[b]!);
  });
}
