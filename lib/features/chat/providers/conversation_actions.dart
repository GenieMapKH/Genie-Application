import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/features/chat/data/chat_repository.dart';
import 'package:genie/features/chat/providers/chat_provider.dart';
import 'package:genie/features/chat/providers/chat_service_providers.dart';

/// Archives, restores and deletes conversations.
///
/// Each takes the conversation off the list it is shown in at once, asks the
/// server, then reloads both lists: the socket that would announce the
/// change may be down. A failed request is rethrown for the screen to show,
/// and the reload puts the conversation back.
class ConversationActions {
  final Ref _ref;

  ConversationActions(this._ref);

  ChatRepository get _repository => _ref.read(chatRepositoryProvider);

  Future<void> archive(String participantId) => _run(
    participantId,
    fromArchive: false,
    () => _repository.archiveConversation(participantId),
  );

  Future<void> unarchive(String participantId) => _run(
    participantId,
    fromArchive: true,
    () => _repository.unarchiveConversation(participantId),
  );

  /// For this user only, or with [forEveryone] for both people, permanently.
  /// [fromArchive] says which list it was deleted from.
  Future<void> delete(
    String participantId, {
    required bool forEveryone,
    required bool fromArchive,
  }) => _run(
    participantId,
    fromArchive: fromArchive,
    () =>
        _repository.deleteConversation(participantId, forEveryone: forEveryone),
  );

  Future<void> _run(
    String participantId,
    Future<void> Function() request, {
    required bool fromArchive,
  }) async {
    (fromArchive
            ? _ref.read(archivedConversationsProvider.notifier)
            : _ref.read(conversationsProvider.notifier))
        .removeLocally(participantId);
    try {
      await request();
    } finally {
      await _refreshLists();
    }
  }

  Future<void> _refreshLists() async {
    await Future.wait([
      _ref.read(conversationsProvider.notifier).refresh(),
      // The archive is only kept while its page is open.
      if (_ref.exists(archivedConversationsProvider))
        _ref.read(archivedConversationsProvider.notifier).refresh(),
    ]);
  }
}

final conversationActionsProvider = Provider<ConversationActions>(
  ConversationActions.new,
);
