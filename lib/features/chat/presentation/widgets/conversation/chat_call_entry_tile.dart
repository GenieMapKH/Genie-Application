import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/chat/models/chat_call_entry.dart';
import 'package:tilomnov/features/chat/presentation/widgets/voice/voice_duration_text.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// A call that took place, as a centred line among the messages:
/// "Outgoing call · 2:34", "Missed call", "No answer"...
class ChatCallEntryTile extends StatelessWidget {
  final ChatCallEntry call;

  /// The person looking at the conversation.
  final String userId;

  const ChatCallEntryTile({
    super.key,
    required this.call,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final outcome = call.outcomeFor(userId);
    final missed = outcome == ChatCallOutcome.missed;
    final color = missed ? context.colors.danger : context.colors.textMuted;
    final text = _text(context.l10n, outcome);

    return Center(
      child: Semantics(
        label: text,
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: context.colors.surface,
            border: Border.all(color: context.colors.border),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_icon(outcome), size: 16, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  text,
                  style: GoogleFonts.inter(fontSize: 13, color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _text(AppLocalizations l10n, ChatCallOutcome outcome) {
    final talkTime = call.talkTime;
    String withTime(String title) =>
        talkTime == null ? title : '$title · ${voiceDurationText(talkTime)}';
    final iCalled = call.callerId == userId;
    return switch (outcome) {
      ChatCallOutcome.completed => withTime(
        iCalled ? l10n.chatCallOutgoing : l10n.chatCallIncoming,
      ),
      ChatCallOutcome.lost => withTime(l10n.chatCallLost),
      ChatCallOutcome.noAnswer => l10n.chatCallNoAnswer,
      ChatCallOutcome.cancelled => l10n.chatCallCancelled,
      ChatCallOutcome.declinedByPeer => l10n.chatCallDeclined,
      ChatCallOutcome.declinedByMe => l10n.chatCallYouDeclined,
      ChatCallOutcome.missed => l10n.chatCallMissed,
    };
  }

  IconData _icon(ChatCallOutcome outcome) {
    return switch (outcome) {
      ChatCallOutcome.missed => Icons.call_missed,
      ChatCallOutcome.declinedByMe => Icons.call_received,
      ChatCallOutcome.completed || ChatCallOutcome.lost =>
        call.callerId == userId ? Icons.call_made : Icons.call_received,
      ChatCallOutcome.noAnswer ||
      ChatCallOutcome.cancelled ||
      ChatCallOutcome.declinedByPeer => Icons.call_made,
    };
  }
}
