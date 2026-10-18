import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/chat/presentation/widgets/conversation_list/chat_conversation_list_view.dart';
import 'package:genie/features/chat/providers/chat_provider.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/shared/widgets/layout/app_header_bar.dart';

/// Conversations the user archived. Swipe or long-press one to move it back
/// or delete it; a new message moves it back by itself.
class ArchivedChatsPage extends ConsumerWidget {
  const ArchivedChatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppHeaderBar(
              title: context.l10n.chatArchivedChats,
              onBackPressed: () => Navigator.of(context).pop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                context.l10n.chatArchivedChatsHint,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: context.colors.textMuted,
                ),
              ),
            ),
            Expanded(
              child: ref
                  .watch(archivedConversationsProvider)
                  .when(
                    data: (conversations) => conversations.isEmpty
                        ? Center(
                            child: Text(
                              context.l10n.chatNoArchivedChats,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: context.colors.textMuted,
                              ),
                            ),
                          )
                        : ChatConversationListView(
                            conversations: conversations,
                            isArchived: true,
                          ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.l10n.chatCouldNotLoadYourChats,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: context.colors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () => ref
                                .read(archivedConversationsProvider.notifier)
                                .refresh(),
                            child: Text(context.l10n.chatTryAgain),
                          ),
                        ],
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
