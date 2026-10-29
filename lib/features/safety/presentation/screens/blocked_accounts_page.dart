import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/safety/data/models/blocked_account.dart';
import 'package:tilomnov/features/safety/presentation/block_actions.dart';
import 'package:tilomnov/features/safety/presentation/view_models/block_providers.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/layout/app_page_scaffold.dart';
import 'package:tilomnov/shared/widgets/media/user_avatar.dart';

/// Everyone the signed-in user blocked, each with a way to unblock them.
class BlockedAccountsPage extends ConsumerWidget {
  const BlockedAccountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final accounts = ref.watch(blockedAccountsProvider);

    return AppPageScaffold(
      title: l10n.blockedAccountsTitle,
      child: RefreshIndicator(
        color: context.colors.accent,
        onRefresh: () => ref.refresh(blockedAccountsProvider.future),
        child: accounts.when(
          skipLoadingOnRefresh: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _Message(
            text: l10n.blockedAccountsLoadFailed,
            onRetry: () => ref.invalidate(blockedAccountsProvider),
          ),
          data: (list) => list.isEmpty
              ? _Message(text: l10n.blockedAccountsEmpty)
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: list.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: context.colors.divider),
                  itemBuilder: (_, index) => _BlockedTile(account: list[index]),
                ),
        ),
      ),
    );
  }
}

class _BlockedTile extends ConsumerWidget {
  final BlockedAccount account;

  const _BlockedTile({required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final name = account.displayName;
    return ListTile(
      leading: UserAvatar(name: name, avatarUrl: account.avatarUrl),
      title: Text(
        name,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
      ),
      subtitle: account.username == null || account.username == name
          ? null
          : Text(
              '@${account.username}',
              style: GoogleFonts.inter(color: colors.textMuted),
            ),
      trailing: OutlinedButton(
        onPressed: () => setBlocked(
          context,
          ref,
          userId: account.id,
          name: name,
          blocked: false,
        ),
        child: Text(context.l10n.unblockAction),
      ),
    );
  }
}

/// A short line in the middle of the page, scrollable so pulling refreshes.
class _Message extends StatelessWidget {
  final String text;
  final VoidCallback? onRetry;

  const _Message({required this.text, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: context.colors.textMuted),
        ),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: Text(context.l10n.commonRetry)),
      ],
    );
  }
}
