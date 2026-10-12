import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/features/chat/presentation/widgets/chat_avatar.dart';
import 'package:genie/features/chat/presentation/widgets/chat_presence_label.dart';
import 'package:genie/features/chat/providers/active_chat_state.dart';
import 'package:genie/features/chat/providers/chat_participant_providers.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';

/// Shows who the user is chatting with, and the code that proves the
/// conversation is encrypted to that person and nobody else.
Future<void> showChatParticipantSheet(
  BuildContext context, {
  required ChatParticipants chat,
  required String participantName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.colors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) =>
        _ChatParticipantSheet(chat: chat, participantName: participantName),
  );
}

class _ChatParticipantSheet extends ConsumerWidget {
  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final ChatParticipants chat;
  final String participantName;

  const _ChatParticipantSheet({
    required this.chat,
    required this.participantName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref
        .watch(chatParticipantProfileProvider(chat.participantId))
        .valueOrNull;
    final safetyCode = ref.watch(chatSafetyCodeProvider(chat));
    final name = profile?.displayName ?? participantName;
    final joined = profile?.memberSince.toLocal();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ChatAvatar(name: name, avatarUrl: profile?.avatarUrl, radius: 40),
            const SizedBox(height: 12),
            Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            ChatPresenceLabel(userId: chat.participantId),
            if (joined != null) ...[
              const SizedBox(height: 4),
              Text(
                'Member since ${_months[joined.month - 1]} ${joined.year}',
                style: _caption(context),
              ),
            ],
            Divider(height: 32, color: context.colors.divider),
            Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 18,
                  color: context.colors.textMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.chatSecurityCode,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            safetyCode.when(
              data: (code) => code == null
                  ? Text(
                      context.l10n.chatAvailableOnceYouHaveBothSet,
                      style: _caption(context),
                    )
                  : _buildCode(context, code, name),
              loading: () => const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, _) => Text(
                context.l10n.chatTheSecurityCodeIsUnavailable,
                style: _caption(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCode(BuildContext context, String code, String name) {
    return Column(
      children: [
        SelectableText(
          code,
          textAlign: TextAlign.center,
          style: GoogleFonts.robotoMono(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          context.l10n.chatSecurityCodeExplanation(name),
          textAlign: TextAlign.center,
          style: _caption(context),
        ),
      ],
    );
  }

  TextStyle _caption(BuildContext context) => GoogleFonts.inter(
    fontSize: 13,
    color: context.colors.textMuted,
    height: 1.4,
  );
}
