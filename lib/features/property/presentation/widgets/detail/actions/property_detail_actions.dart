import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:tilomnov/core/device/app_haptics.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/shared/widgets/buttons/tactile_button.dart';
import 'package:tilomnov/shared/widgets/glass/glass_icon_button.dart';
import 'package:tilomnov/shared/widgets/glass/glass_scope.dart';

/// The close, favourite and share buttons floating over the detail gallery,
/// and a "more" menu after them.
class PropertyDetailActions extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onClose;
  final VoidCallback onFavoriteToggled;
  final VoidCallback? onShare;

  /// Drawn in the same round button as the others.
  final Widget? menu;

  const PropertyDetailActions({
    super.key,
    required this.isFavorite,
    required this.onClose,
    required this.onFavoriteToggled,
    this.onShare,
    this.menu,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      // With glass, the buttons share one read of the photo behind them.
      child: BackdropGroup(
        child: Row(
          children: [
            _CircleButton(icon: LucideIcons.x, onPressed: onClose),
            const Spacer(),
            _CircleButton(
              icon: isFavorite ? LucideIcons.heart : LucideIcons.heart,
              iconColor: isFavorite ? context.colors.accent : null,
              onPressed: () {
                if (!isFavorite) AppHaptics.lightTap();
                onFavoriteToggled();
              },
            ),
            const SizedBox(width: 10),
            _CircleButton(icon: LucideIcons.share, onPressed: onShare),
            if (menu case final menu?) ...[
              const SizedBox(width: 10),
              _Circle(child: menu),
            ],
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onPressed;

  const _CircleButton({required this.icon, this.iconColor, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TactileButton(
      pressedScale: 0.9,
      onPressed: onPressed,
      child: _Circle(
        child: Icon(
          icon,
          size: 20,
          color: iconColor ?? context.colors.textPrimary,
        ),
      ),
    );
  }
}

/// The round, shadowed surface every button here sits on: glass over the
/// photo on phones whose interface is glass.
class _Circle extends StatelessWidget {
  final Widget child;

  const _Circle({required this.child});

  static const double _size = 38;

  @override
  Widget build(BuildContext context) {
    if (GlassScope.of(context)) {
      return GlassCircle(size: _size, child: child);
    }
    return Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.colors.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
