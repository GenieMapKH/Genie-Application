import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/shared/widgets/layout/app_header_bar.dart';
import 'package:tilomnov/features/chat/presentation/screens/archived_chats_page.dart';
import 'package:tilomnov/features/chat/presentation/widgets/conversation_list/chat_conversation_list_view.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/features/chat/providers/chat_provider.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/features/profile/presentation/view_models/user_providers.dart';
import 'package:tilomnov/shared/widgets/feedback/page_load_failure.dart';
import 'package:tilomnov/shared/widgets/layout/paused_while_hidden.dart';
import 'package:tilomnov/shared/widgets/menus/app_menu_item.dart';

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
      // The list carries on behind a floating navigation bar; it pads itself
      // to end above it.
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppHeaderBar(
              title: context.l10n.navChat,
              onBackPressed: widget.onBackPressed,
              trailing: _buildMoreMenu(),
            ),
            Expanded(
              // Kept while another tab is shown: new messages redraw the
              // list only once it is shown again.
              child: PausedWhileHidden(
                builder: (context, ref) => ref
                    .watch(conversationsProvider)
                    .when(
                      data: (list) {
                        if (list.items.isEmpty) return _buildEmptyState();
                        return ChatConversationListView(
                          page: list.page,
                          isArchived: false,
                          onLoadMore: () => ref
                              .read(conversationsProvider.notifier)
                              .loadMore(),
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => _buildErrorState(err),
                    ),
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
      itemBuilder: (menuContext) => [
        appMenuItem<void>(
          menuContext,
          icon: Icons.archive_outlined,
          label: context.l10n.chatArchivedChats,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ArchivedChatsPage())),
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

  Widget _buildErrorState(Object error) {
    return PageLoadFailure(
      error: error,
      message: context.l10n.chatCouldNotLoadYourChats,
      onRetry: _retry,
    );
  }

  /// Without the profile it is not known whose chats to load: that is read
  /// again first.
  void _retry() {
    if (ref.read(userProfileProvider).hasError) {
      ref.invalidate(userProfileProvider);
    } else {
      ref.read(conversationsProvider.notifier).refresh();
    }
  }
}
