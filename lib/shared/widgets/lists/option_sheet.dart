import 'package:flutter/material.dart';

import 'package:tilomnov/core/theme/app_colors.dart';

/// One choice in an [showOptionSheet].
class SheetOption<T> {
  final T value;
  final String label;

  const SheetOption(this.value, this.label);
}

/// Bottom sheet for picking one of a few [options]; the one in use is ticked.
/// Returns the picked option, or null when the sheet is dismissed.
///
/// [footer] is shown under the options and stays open when used: for a
/// related setting that is not one of the choices.
Future<SheetOption<T>?> showOptionSheet<T>(
  BuildContext context, {
  required String title,
  required List<SheetOption<T>> options,
  required T selected,
  Widget? footer,
}) {
  return showModalBottomSheet<SheetOption<T>>(
    context: context,
    useRootNavigator: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      final colors = sheetContext.colors;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
            for (final option in options)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(
                  option.label,
                  style: TextStyle(fontSize: 15, color: colors.textPrimary),
                ),
                trailing: option.value == selected
                    ? Icon(Icons.check, color: colors.accent)
                    : null,
                onTap: () => Navigator.pop(sheetContext, option),
              ),
            if (footer != null) ...[
              Divider(height: 16, color: colors.border),
              footer,
            ],
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
