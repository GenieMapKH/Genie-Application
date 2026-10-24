import 'package:flutter/material.dart';
import 'package:genie/core/theme/app_colors.dart';

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
      child: Row(
        children: [
          _CircleButton(icon: Icons.close, onPressed: onClose),
          const Spacer(),
          _CircleButton(
            icon: isFavorite ? Icons.favorite : Icons.favorite_border,
            iconColor: isFavorite ? context.colors.accent : null,
            onPressed: onFavoriteToggled,
          ),
          const SizedBox(width: 10),
          _CircleButton(icon: Icons.ios_share, onPressed: onShare),
          if (menu case final menu?) ...[
            const SizedBox(width: 10),
            _Circle(child: menu),
          ],
        ],
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
    return GestureDetector(
      onTap: onPressed,
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

/// The round, shadowed surface every button here sits on.
class _Circle extends StatelessWidget {
  final Widget child;

  const _Circle({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
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
