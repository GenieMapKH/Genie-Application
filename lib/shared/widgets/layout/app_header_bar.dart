import 'package:flutter/material.dart';

import 'package:tilomnov/core/theme/app_colors.dart';

/// Standardized, consistent top app header bar used across screens (Account, Saved Properties, My Properties, etc.).
class AppHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final Widget? trailing;
  final bool showBackButton;

  /// Defaults to the page background of the theme in use.
  final Color? backgroundColor;

  const AppHeaderBar({
    super.key,
    required this.title,
    this.onBackPressed,
    this.trailing,
    this.showBackButton = true,
    this.backgroundColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56.0);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      color: backgroundColor ?? colors.background,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Back Button
          if (showBackButton)
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (onBackPressed != null) {
                    onBackPressed!();
                  } else if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.arrow_back,
                    color: colors.textPrimary,
                    size: 24,
                  ),
                ),
              ),
            ),

          // Centered Title. The padding keeps a long (translated) title clear
          // of the back button and the trailing widget.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ),

          // Trailing Widget (e.g. Saved count badge or Action button)
          if (trailing != null)
            Align(alignment: Alignment.centerRight, child: trailing!),
        ],
      ),
    );
  }
}
