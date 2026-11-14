import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

/// Reserved for accounts whose server-provided role is admin.
class AdminAvatarFrame extends StatelessWidget {
  final Widget child;
  const AdminAvatarFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Tilomnov administrator',
    child: Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFF9DF93), Color(0xFFB88935), Color(0xFF183B62)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB88935).withValues(alpha: .2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          const Positioned(
            top: -5,
            right: -5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFF183B62),
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: EdgeInsets.all(3),
                child: Icon(
                  LucideIcons.badgeCheck,
                  size: 14,
                  color: Color(0xFFF9DF93),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class AdminIdentityBadge extends StatelessWidget {
  const AdminIdentityBadge({super.key});

  @override
  Widget build(BuildContext context) => const Chip(
    avatar: Icon(LucideIcons.badgeCheck, size: 16, color: Color(0xFFF9DF93)),
    label: Text('Tilomnov Admin'),
    labelStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    backgroundColor: Color(0xFF183B62),
    side: BorderSide(color: Color(0xFFB88935)),
    visualDensity: VisualDensity.compact,
  );
}
