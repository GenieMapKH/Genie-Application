import 'package:flutter/material.dart';

/// The close, favourite and share buttons floating over the detail gallery.
class PropertyDetailActions extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onClose;
  final VoidCallback onFavoriteToggled;
  final VoidCallback? onShare;

  const PropertyDetailActions({
    super.key,
    required this.isFavorite,
    required this.onClose,
    required this.onFavoriteToggled,
    this.onShare,
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
            iconColor: isFavorite ? const Color(0xFFE5484D) : null,
            onPressed: onFavoriteToggled,
          ),
          const SizedBox(width: 10),
          _CircleButton(icon: Icons.ios_share, onPressed: onShare),
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
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: iconColor ?? const Color(0xFF111827)),
      ),
    );
  }
}
