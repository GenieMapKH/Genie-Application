import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/safety/data/models/block_status.dart';
import 'package:tilomnov/features/safety/presentation/block_actions.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// In place of the message bar when the two cannot message: the blocker
/// can unblock from here; the person blocked is only told they cannot reply.
class BlockedConversationBar extends ConsumerWidget {
  final BlockStatus status;
  final String participantId;
  final String participantName;

  const BlockedConversationBar({
    super.key,
    required this.status,
    required this.participantId,
    required this.participantName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;

    return Container(
      width: double.infinity,
      color: colors.surface,
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            status.isBlocked
                ? l10n.chatYouBlocked(participantName)
                : l10n.chatCannotReply,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: colors.textMuted),
          ),
          if (status.isBlocked)
            TextButton(
              onPressed: () => setBlocked(
                context,
                ref,
                userId: participantId,
                name: participantName,
                blocked: false,
              ),
              child: Text(l10n.unblockAction),
            ),
        ],
      ),
    );
  }
}
