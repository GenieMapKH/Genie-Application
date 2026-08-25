import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/google_icon.dart';

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
          text: 'Sign up',
          isLoading: isLoading,
          onPressed: onSignUp,
        ),
        const SizedBox(height: 24),

        // Divider: "or sign in with"
        Row(
          children: [
            const Expanded(
              child: Divider(color: Color(0xFFE5E7EB), thickness: 1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'or sign in with',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ),
            const Expanded(
              child: Divider(color: Color(0xFFE5E7EB), thickness: 1),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Google OAuth Button
        AppButton(
          key: const Key('google_button'),
          text: 'Continue with Google',
          backgroundColor: Colors.white,
          textColor: const Color(0xFF1F2937),
          borderColor: const Color(0xFFE5E7EB),
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
                'Already have an account? ',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
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
                    'Sign in here',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4F5BD5),
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
