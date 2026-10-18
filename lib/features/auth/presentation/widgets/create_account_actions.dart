import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/media/google_icon.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';

class CreateAccountActions extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onSignUp;
  final VoidCallback? onGoogleSignUp;
  final VoidCallback onSignInHere;

  const CreateAccountActions({
    super.key,
    required this.isLoading,
    required this.onSignUp,
    this.onGoogleSignUp,
    required this.onSignInHere,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Primary Sign up Button (#4F5BD5)
        AppButton.primary(
          key: const Key('sign_up_button'),
          text: context.l10n.authSignUp,
          isLoading: isLoading,
          onPressed: onSignUp,
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

        // Google OAuth Button
        AppButton(
          key: const Key('google_button'),
          text: context.l10n.authContinueWithGoogle,
          backgroundColor: context.colors.surface,
          textColor: context.colors.textPrimary,
          borderColor: context.colors.border,
          borderWidth: 1.5,
          icon: const GoogleIcon(size: 20),
          onPressed: onGoogleSignUp ?? () {},
        ),
        const SizedBox(height: 48),

        // Bottom Link: Already have an account? Sign in here
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                context.l10n.authAlreadyHaveAnAccount,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: context.colors.textMuted,
                ),
              ),
              GestureDetector(
                key: const Key('sign_in_here_link'),
                behavior: HitTestBehavior.opaque,
                onTap: onSignInHere,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.0,
                    vertical: 6.0,
                  ),
                  child: Text(
                    context.l10n.authSignInHere,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.colors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
