import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/search/data/models/publisher_summary.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/shared/utils/app_popup.dart';

/// How to reach a publisher: phone and email, each copied with a tap.
/// Draws nothing when they have neither.
class PublisherContactCard extends StatelessWidget {
  final PublisherSummary person;

  const PublisherContactCard({super.key, required this.person});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = [
      if (person.phone case final phone?)
        _ContactRow(
          icon: Icons.phone_outlined,
          label: l10n.profilePhone,
          value: phone,
        ),
      if (person.email case final email?)
        _ContactRow(
          icon: Icons.mail_outline_rounded,
          label: l10n.profileEmail,
          value: email,
        ),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              l10n.profileContactTitle,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colors.textMuted,
              ),
            ),
          ),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 56, color: colors.divider),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      AppPopup.showSuccess(context, context.l10n.profileCopied(label));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: () => _copy(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: colors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: colors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _copy(context),
              tooltip: '${context.l10n.profileCopy} $label',
              icon: Icon(Icons.copy_rounded, size: 18, color: colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
