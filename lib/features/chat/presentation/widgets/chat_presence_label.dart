import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/features/chat/models/chat_participant.dart';
import 'package:genie/features/chat/providers/chat_participant_providers.dart';

/// "Online", "Last seen 5 min ago", … or empty when nothing is known.
String describePresence(ChatPresence presence, {DateTime? now}) {
  if (presence.online) return 'Online';

  final lastSeen = presence.lastSeenAt?.toLocal();
  if (lastSeen == null) return '';

  final current = now ?? DateTime.now();
  final ago = current.difference(lastSeen);
  if (ago.inMinutes < 1) return 'Last seen just now';
  if (ago.inMinutes < 60) return 'Last seen ${ago.inMinutes} min ago';

  final time =
      '${lastSeen.hour.toString().padLeft(2, '0')}:'
      '${lastSeen.minute.toString().padLeft(2, '0')}';
  final today = DateTime(current.year, current.month, current.day);
  final day = DateTime(lastSeen.year, lastSeen.month, lastSeen.day);
  final daysAgo = today.difference(day).inDays;
  if (daysAgo == 0) return 'Last seen today at $time';
  if (daysAgo == 1) return 'Last seen yesterday at $time';
  return 'Last seen ${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
}

/// Live online / last-seen line for one user. Takes no space until known.
class ChatPresenceLabel extends ConsumerWidget {
  final String userId;

  const ChatPresenceLabel({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presence = ref.watch(chatPresenceProvider(userId)).valueOrNull;
    final label = presence == null ? '' : describePresence(presence);
    if (label.isEmpty) return const SizedBox.shrink();

    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 12,
        color: presence!.online
            ? const Color(0xFF16A34A)
            : const Color(0xFF6B7280),
      ),
    );
  }
}
