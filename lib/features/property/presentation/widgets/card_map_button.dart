import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/glass/glass_icon_button.dart';
import 'package:tilomnov/shared/widgets/glass/glass_scope.dart';

/// The round "View on map" button on a listing card's photo, drawn like the
/// heart beside it: glass on glass phones, a white disc elsewhere.
class CardMapButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CardMapButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final tooltip = context.l10n.propertyViewOnMap;
    if (GlassScope.of(context)) {
      return SizedBox.square(
        dimension: 44,
        child: Center(
          child: GlassIconButton(
            icon: LucideIcons.map,
            tooltip: tooltip,
            onPressed: onPressed,
            size: 32,
            iconSize: 18,
          ),
        ),
      );
    }
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.square(
          dimension: 44,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: context.colors.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                LucideIcons.map,
                size: 18,
                color: context.colors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
