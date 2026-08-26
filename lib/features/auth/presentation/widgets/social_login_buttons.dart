import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/google_icon.dart';

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
                text: 'Login',
                isLoading: isLoading,
                onPressed: onLogin,
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

              // Google OAuth Login Button
              AppButton(
                text: 'Continue with Google',
                backgroundColor: Colors.white,
                textColor: const Color(0xFF1F2937),
                borderColor: const Color(0xFFE5E7EB),
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
                      'Create a Account',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4F5BD5),
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
