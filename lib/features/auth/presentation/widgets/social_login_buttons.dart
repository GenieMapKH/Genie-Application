import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/google_icon.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';

class LoginActions extends StatelessWidget {
  final Animation<Offset> slideAnimation;
  final Animation<double> fadeAnimation;
  final bool isLoading;
  final VoidCallback onLogin;
  final VoidCallback? onGoogleLogin;
  final VoidCallback? onCreateAccount;

  const LoginActions({
    super.key,
    required this.slideAnimation,
    required this.fadeAnimation,
    required this.isLoading,
    required this.onLogin,
    this.onGoogleLogin,
    this.onCreateAccount,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SlideTransition(
        position: slideAnimation,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: Column(
            children: [
              // Primary Login Button (#4F5BD5)
              AppButton.primary(
                text: context.l10n.authLogin,
                isLoading: isLoading,
                onPressed: onLogin,
              ),
              const SizedBox(height: 24),

              // Divider: "or sign in with"
              Row(
                children: [
                  Expanded(
                    child: Divider(color: context.colors.border, thickness: 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      context.l10n.authOrSignInWith,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: context.colors.textHint,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: context.colors.border, thickness: 1),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Google OAuth Login Button
              AppButton(
                text: context.l10n.authContinueWithGoogle,
                backgroundColor: context.colors.surface,
                textColor: context.colors.textPrimary,
                borderColor: context.colors.border,
                borderWidth: 1.5,
                icon: const GoogleIcon(size: 20),
                onPressed: onGoogleLogin ?? () {},
              ),
              const SizedBox(height: 54),

              // Bottom Link: Create a Account
              Center(
                child: GestureDetector(
                  onTap:
                      onCreateAccount ??
                      () {
                        context.go('/register');
                      },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      context.l10n.authCreateAAccount,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.colors.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
