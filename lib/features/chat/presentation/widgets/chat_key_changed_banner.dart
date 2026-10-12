import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genie/l10n/l10n.dart';

/// Shown instead of the message box when the other person's encryption key
/// is not the one this device trusts. Nothing is sent until the user decides.
class ChatKeyChangedBanner extends StatelessWidget {
  final String participantName;
  final VoidCallback onAccept;
  final VoidCallback onViewSecurityCode;

  const ChatKeyChangedBanner({
    super.key,
    required this.participantName,
    required this.onAccept,
    required this.onViewSecurityCode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFFBEB),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFB45309),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "$participantName's security key has changed",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.chatThisIsNormalIfTheyReinstalled,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF92400E),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onViewSecurityCode,
                child: Text(context.l10n.chatSecurityCode),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onAccept,
                child: Text(context.l10n.chatAcceptNewKey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
