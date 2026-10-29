import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/forms/app_text_field.dart';

import '../view_models/login_form_provider.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/l10n/l10n.dart';

class LoginForm extends StatelessWidget {
  final Animation<Offset> slideAnimation;
  final Animation<double> fadeAnimation;
  final AuthMethod selectedMethod;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final String? emailError;
  final String? phoneError;
  final String? passwordError;
  final bool obscurePassword;
  final bool keepMeSignedIn;
  final Function(String) onEmailChanged;
  final Function(String) onPhoneChanged;
  final Function(String) onPasswordChanged;
  final VoidCallback onTogglePasswordVisibility;
  final Function(bool?) onKeepMeSignedInChanged;
  final VoidCallback? onForgotPasswordPressed;

  const LoginForm({
    super.key,
    required this.slideAnimation,
    required this.fadeAnimation,
    required this.selectedMethod,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    this.emailError,
    this.phoneError,
    this.passwordError,
    required this.obscurePassword,
    required this.keepMeSignedIn,
    required this.onEmailChanged,
    required this.onPhoneChanged,
    required this.onPasswordChanged,
    required this.onTogglePasswordVisibility,
    required this.onKeepMeSignedInChanged,
    this.onForgotPasswordPressed,
  });

  @override
  Widget build(BuildContext context) {
    return
    // Form Fields with Directional Slide & Fade Transition
    RepaintBoundary(
      child: SlideTransition(
        position: slideAnimation,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final isEmail = child.key == const Key('email_field');
                  final offsetTween = Tween<Offset>(
                    begin: isEmail
                        ? const Offset(-0.08, 0)
                        : const Offset(0.08, 0),
                    end: Offset.zero,
                  );
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: offsetTween.animate(animation),
                      child: child,
                    ),
                  );
                },
                child: selectedMethod == AuthMethod.email
                    ? AppTextField(
                        key: const Key('email_field'),
                        label: context.l10n.authEmailAddress,
                        hintText: context.l10n.authExampleGmailCom,
                        errorText: emailError,
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onChanged: onEmailChanged,
                      )
                    : AppTextField(
                        key: const Key('phone_field'),
                        label: context.l10n.personalInfoPhone,
                        hintText: context.l10n.personalInfoPhone,
                        errorText: phoneError,
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        onChanged: onPhoneChanged,
                      ),
              ),
              const SizedBox(height: 20),

              // Password Field with "Forget Password?" link & Error handling
              AppTextField(
                key: const Key('password_field'),
                label: context.l10n.identityConfirmPassword,
                hintText: '********',
                errorText: passwordError,
                controller: passwordController,
                obscureText: obscurePassword,
                textInputAction: TextInputAction.done,
                onChanged: onPasswordChanged,
                topTrailingWidget: GestureDetector(
                  onTap: onForgotPasswordPressed ?? () {},
                  child: Text(
                    context.l10n.authForgetPassword,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.colors.primary,
                    ),
                  ),
                ),
                suffixIcon: IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Icon(
                      obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      key: ValueKey<bool>(obscurePassword),
                      color: context.colors.textMuted,
                      size: 20,
                    ),
                  ),
                  onPressed: onTogglePasswordVisibility,
                ),
              ),
              const SizedBox(height: 16),

              // Keep me signed in Checkbox
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: keepMeSignedIn,
                      activeColor: context.colors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      side: BorderSide(
                        color: context.colors.iconSubtle,
                        width: 1.5,
                      ),
                      onChanged: onKeepMeSignedInChanged,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: GestureDetector(
                      onTap: () => onKeepMeSignedInChanged(!keepMeSignedIn),
                      child: Text(
                        context.l10n.authKeepMeSignedIn,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
