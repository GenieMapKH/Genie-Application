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
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/feedback/failure_message.dart';

/// Who the user is chatting with, in two tabs: "Profile" (and a way to
/// their full profile page) and "Security code", the code that proves the
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
      child: DefaultTabController(
        length: 2,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              UserAvatar(name: name, avatarUrl: profile?.avatarUrl, radius: 40),
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
              TabBar(
                labelColor: colors.accent,
                unselectedLabelColor: colors.textMuted,
                indicatorColor: colors.accent,
                dividerColor: colors.divider,
                labelStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(
                    icon: const Icon(Icons.person_outline_rounded, size: 20),
                    text: context.l10n.chatTabProfile,
                  ),
                  Tab(
                    icon: const Icon(Icons.lock_outline, size: 20),
                    text: context.l10n.chatSecurityCode,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Not a TabBarView: that needs a fixed height, and the two tabs
              // differ, so the sheet grows to whichever is shown.
              Builder(
                builder: (context) {
                  final tabs = DefaultTabController.of(context);
                  return AnimatedBuilder(
                    animation: tabs,
                    builder: (context, _) => AnimatedSize(
                      duration: const Duration(milliseconds: 180),
                      alignment: Alignment.topCenter,
                      child: tabs.index == 0
                          ? _ProfileTab(
                              profile: profile,
                              participantName: name,
                              onViewProfile: _profileOpener(context, ref, name),
                            )
                          : _SecurityTab(chat: chat, participantName: name),
                    ),
                  );
                },
              ),
            ],
          ),
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

class _SecurityTab extends ConsumerWidget {
  final ChatParticipants chat;
  final String participantName;

  const _SecurityTab({required this.chat, required this.participantName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safetyCode = ref.watch(chatSafetyCodeProvider(chat));

    return safetyCode.when(
      data: (code) => code == null
          ? Text(
              context.l10n.chatAvailableOnceYouHaveBothSet,
              textAlign: TextAlign.center,
              style: _caption(context),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
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
                  context.l10n.chatSecurityCodeExplanation(participantName),
                  textAlign: TextAlign.center,
                  style: _caption(context),
                ),
              ],
            ),
      loading: () => const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (error, _) => Text(
        failureMessage(
          context.l10n,
          error: error,
          fallback: context.l10n.chatTheSecurityCodeIsUnavailable,
        ),
        textAlign: TextAlign.center,
        style: _caption(context),
      ),
    );
  }
}

TextStyle _caption(BuildContext context) => GoogleFonts.inter(
  fontSize: 13,
  color: context.colors.textMuted,
  height: 1.4,
);
