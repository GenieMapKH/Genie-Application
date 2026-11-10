import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/auth/presentation/view_models/login_form_provider.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// "Email | Phone number", with a sliding underline under the chosen one.
/// Signing in and resetting a password both ask which the user has.
class AuthMethodTabs extends StatelessWidget {
  final AuthMethod selected;
  final ValueChanged<AuthMethod> onSelected;

  const AuthMethodTabs({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isEmail = selected == AuthMethod.email;

    return SizedBox(
      height: 34,
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          Row(
            children: [
              _Tab(
                label: context.l10n.personalInfoEmail,
                active: isEmail,
                onTap: () => onSelected(AuthMethod.email),
              ),
              const SizedBox(width: 24),
              _Tab(
                label: context.l10n.authPhoneNumber,
                active: !isEmail,
                onTap: () => onSelected(AuthMethod.phone),
              ),
            ],
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            left: isEmail ? 0 : 64.0,
            bottom: 0,
            width: isEmail ? 40.0 : 110.0,
            height: 2.0,
            child: Container(
              decoration: BoxDecoration(
                color: context.colors.primary,
                borderRadius: BorderRadius.circular(1.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Tab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6.0),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            color: active ? context.colors.primary : context.colors.textMuted,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
