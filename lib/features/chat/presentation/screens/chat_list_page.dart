import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/shared/widgets/layout/app_header_bar.dart';
import 'package:genie/features/chat/presentation/screens/archived_chats_page.dart';
import 'package:genie/features/chat/presentation/widgets/conversation_list/chat_conversation_list_view.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/features/chat/providers/chat_provider.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';

class ChatListPage extends ConsumerStatefulWidget {
  final bool isEmbedded;
  final VoidCallback? onBackPressed;

  const ChatListPage({super.key, this.isEmbedded = false, this.onBackPressed});

  @override
  ConsumerState<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends ConsumerState<ChatListPage> {
  @override
  void initState() {
    super.initState();
    // PIN prompt will only occur when navigating to a ChatConversationPage
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppHeaderBar(
              title: context.l10n.navChat,
              onBackPressed: widget.onBackPressed,
              trailing: _buildMoreMenu(),
            ),
            Expanded(
              child: ref
                  .watch(conversationsProvider)
                  .when(
                    data: (conversations) {
                      if (conversations.isEmpty) return _buildEmptyState();
                      return ChatConversationListView(
                        conversations: conversations,
                        isArchived: false,
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => _buildErrorState(),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// The coloured "more" button at the top right: the way into the archive.
  Widget _buildMoreMenu() {
    return PopupMenuButton<void>(
      tooltip: context.l10n.chatMoreOptions,
      icon: Icon(Icons.more_vert, color: context.colors.accent),
      color: context.colors.surface,
      itemBuilder: (menuContext) => [
        PopupMenuItem<void>(
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ArchivedChatsPage())),
          child: Row(
            children: [
              Icon(Icons.archive_outlined, color: context.colors.textSecondary),
              const SizedBox(width: 12),
              Text(context.l10n.chatArchivedChats),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.colors.divider,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: context.colors.textHint,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n.chatNoChatsYet,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.chatMessageAPropertyOwnerToStart,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: context.colors.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
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
            onPressed: () => ref.read(conversationsProvider.notifier).refresh(),
            child: Text(context.l10n.chatTryAgain),
          ),
        ],
      ),
    );
  }
}
