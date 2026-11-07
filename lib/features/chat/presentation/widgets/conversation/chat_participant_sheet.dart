import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:tilomnov/shared/widgets/media/user_avatar.dart';
import 'package:tilomnov/features/chat/models/chat_participant.dart';
import 'package:tilomnov/features/chat/presentation/widgets/conversation/chat_presence_label.dart';
import 'package:tilomnov/features/chat/providers/active_chat_state.dart';
import 'package:tilomnov/features/chat/providers/chat_participant_providers.dart';
import 'package:tilomnov/features/chat/providers/chat_profile_opener.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/safety/presentation/widgets/safety_menu_button.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// Profile summary, full profile link, and safety menu for the participant.
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
    builder: (_) => _ChatParticipantSheet(
      chat: chat,
      participantName: participantName,
      // The conversation's context: the sheet's own is gone once it closes,
      // and the profile page opens after that.
      hostContext: context,
    ),
  );
}

class _ChatParticipantSheet extends ConsumerWidget {
  final ChatParticipants chat;
  final String participantName;
  final BuildContext hostContext;

  const _ChatParticipantSheet({
    required this.chat,
    required this.participantName,
    required this.hostContext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref
        .watch(chatParticipantProfileProvider(chat.participantId))
        .valueOrNull;
    final name = profile?.displayName ?? participantName;
    final colors = context.colors;

    return SafeArea(
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  UserAvatar(
                    name: name,
                    avatarUrl: profile?.avatarUrl,
                    radius: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ChatPresenceLabel(userId: chat.participantId),
                  const SizedBox(height: 16),
                  _ProfileTab(
                    profile: profile,
                    participantName: name,
                    onViewProfile: _profileOpener(context, ref, name),
                  ),
                ],
              ),
            ),
            if (chat.userId != chat.participantId)
              Positioned(
                top: 8,
                right: 8,
                child: SafetyMenuButton(
                  userId: chat.participantId,
                  userName: name,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Null when the app supplies no profile page (the button is then hidden).
  VoidCallback? _profileOpener(
    BuildContext sheetContext,
    WidgetRef ref,
    String name,
  ) {
    final openProfile = ref.watch(chatProfileOpenerProvider);
    if (openProfile == null) return null;

    return () {
      final profile = ref
          .read(chatParticipantProfileProvider(chat.participantId))
          .valueOrNull;
      Navigator.of(sheetContext).pop();
      openProfile(
        hostContext,
        ChatProfileTarget(
          userId: chat.participantId,
          name: name,
          username: profile?.username,
          avatarUrl: profile?.avatarUrl,
        ),
      );
    };
  }
}

class _ProfileTab extends StatelessWidget {
  final ChatParticipantProfile? profile;
  final String participantName;
  final VoidCallback? onViewProfile;

  const _ProfileTab({
    required this.profile,
    required this.participantName,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final handle = profile?.username;
    final joined = profile?.memberSince.toLocal();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (handle != null && handle != participantName)
          Text(
            '@$handle',
            style: GoogleFonts.inter(fontSize: 14, color: colors.textMuted),
          ),
        if (joined != null) ...[
          const SizedBox(height: 4),
          Text(
            context.l10n.profileMemberSince(
              DateFormat.yMMMM(
                Localizations.localeOf(context).toLanguageTag(),
              ).format(joined),
            ),
            style: _caption(context),
          ),
        ],
        if (onViewProfile != null) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onViewProfile,
            icon: const Icon(Icons.account_circle_outlined, size: 18),
            label: Text(
              context.l10n.chatViewFullProfile,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: colors.onPrimary,
              minimumSize: const Size(220, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

TextStyle _caption(BuildContext context) => GoogleFonts.inter(
  fontSize: 13,
  color: context.colors.textMuted,
  height: 1.4,
);
