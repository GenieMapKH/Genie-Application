import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:go_router/go_router.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/shared/widgets/glass/glass_icon_button.dart';
import 'package:tilomnov/shared/widgets/glass/glass_scope.dart';

/// The back button at the top of the password and code screens: round
/// glass on phones whose interface is glass, else an outlined square.
class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (GlassScope.of(context)) {
      return GlassIconButton.back(onPressed: () => context.pop());
    }
    return GestureDetector(
      onTap: () => context.pop(),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: context.colors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          LucideIcons.arrowLeft,
          size: 20,
          color: context.colors.textPrimary,
        ),
      ),
    );
  }
}
