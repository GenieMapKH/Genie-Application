import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_visibility.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// Lets the owner pick Public, Draft or Sold for a listing now of [status].
/// Resolves to the choice, or null when dismissed. A choice the server would
/// refuse is shown disabled, with why.
class PropertyVisibilitySheet extends StatelessWidget {
  final String status;

  const PropertyVisibilitySheet({super.key, required this.status});

  static Future<PropertyVisibility?> show(BuildContext context, String status) {
    return showModalBottomSheet<PropertyVisibility>(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PropertyVisibilitySheet(status: status),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = PropertyVisibility.of(status);
    final l10n = context.l10n;

    Widget option(
      PropertyVisibility value,
      IconData icon,
      String title,
      String hint,
    ) {
      final isCurrent = value == current;
      final allowed = visibilityChange(status, value) != null;
      final reason = !isCurrent && !allowed && value == PropertyVisibility.sold
          ? l10n.propertyVisibilitySoldNeedsPublic
          : hint;
      final color = isCurrent || allowed
          ? context.colors.textPrimary
          : context.colors.textHint;

      return ListTile(
        enabled: allowed,
        leading: Icon(icon, color: isCurrent ? context.colors.accent : color),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        subtitle: Text(
          reason,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: context.colors.textMuted,
          ),
        ),
        trailing: isCurrent
            ? Icon(Icons.check_circle, color: context.colors.accent)
            : null,
        onTap: () => Navigator.of(context).pop(value),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                l10n.propertyVisibility,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                ),
              ),
            ),
            option(
              PropertyVisibility.public,
              Icons.public,
              l10n.propertyVisibilityPublic,
              l10n.propertyVisibilityPublicHint,
            ),
            option(
              PropertyVisibility.draft,
              Icons.lock_outline,
              l10n.propertyVisibilityDraft,
              l10n.propertyVisibilityDraftHint,
            ),
            option(
              PropertyVisibility.sold,
              Icons.sell_outlined,
              l10n.propertyVisibilitySold,
              l10n.propertyVisibilitySoldHint,
            ),
          ],
        ),
      ),
    );
  }
}
