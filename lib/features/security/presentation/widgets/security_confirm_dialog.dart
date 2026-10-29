import 'package:flutter/material.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// Asks before a security change. True when the user chose [action].
/// [isDestructive] paints the action in the danger colour.
Future<bool> showSecurityConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
  required bool isDestructive,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(dialogContext.l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: isDestructive
              ? TextButton.styleFrom(
                  foregroundColor: dialogContext.colors.danger,
                )
              : null,
          child: Text(action),
        ),
      ],
    ),
  );
  return confirmed == true;
}
