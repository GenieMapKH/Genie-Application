import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/forms/app_text_field.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// The sign-up fields: name, phone number (required), email (optional),
/// password, and agreeing to the terms. Shows what it is given; the page
/// decides what is wrong.
class CreateAccountForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String? nameError;
  final String? phoneError;
  final String? emailError;
  final String? passwordError;
  final String? termsError;
  final bool obscurePassword;
  final bool agreeToTerms;

  /// Any field was edited.
  final VoidCallback onChanged;
  final VoidCallback onTogglePasswordVisibility;
  final ValueChanged<bool> onTermsChanged;

  /// Opens the terms to read. Agreeing does not need it.
  final VoidCallback onTermsLinkTapped;

  const CreateAccountForm({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.emailController,
    required this.passwordController,
    this.nameError,
    this.phoneError,
    this.emailError,
    this.passwordError,
    this.termsError,
    required this.obscurePassword,
    required this.agreeToTerms,
    required this.onChanged,
    required this.onTogglePasswordVisibility,
    required this.onTermsChanged,
    required this.onTermsLinkTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          key: const Key('name_field'),
          label: context.l10n.personalInfoName,
          hintText: context.l10n.personalInfoUsername,
          errorText: nameError,
          controller: nameController,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 20),
        AppTextField(
          key: const Key('phone_field'),
          label: context.l10n.authPhoneNumber,
          hintText: context.l10n.authPhoneHint,
          errorText: phoneError,
          controller: phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 20),
        AppTextField(
          key: const Key('email_field'),
          label: context.l10n.authEmailOptional,
          hintText: context.l10n.authExampleGmailCom,
          errorText: emailError,
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 20),
        AppTextField(
          key: const Key('password_field'),
          label: context.l10n.identityConfirmPassword,
          hintText: '••••••••••••',
          errorText: passwordError,
          controller: passwordController,
          obscureText: obscurePassword,
          textInputAction: TextInputAction.done,
          onChanged: (_) => onChanged(),
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
        const SizedBox(height: 12),
        _TermsAgreement(
          agreed: agreeToTerms,
          hasError: termsError != null,
          onChanged: onTermsChanged,
          onLinkTapped: onTermsLinkTapped,
        ),
        if (termsError != null)
          Padding(
            padding: const EdgeInsets.only(top: 2.0, left: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1.0),
                  child: Icon(
                    Icons.info_outline,
                    size: 14.0,
                    color: Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    termsError!,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: const Color(0xFFDC2626),
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

/// A large tick box: tapping anywhere on the row agrees (or un-agrees).
/// Only the underlined words open the terms, for whoever wants to read them.
class _TermsAgreement extends StatelessWidget {
  final bool agreed;
  final bool hasError;
  final ValueChanged<bool> onChanged;
  final VoidCallback onLinkTapped;

  const _TermsAgreement({
    required this.agreed,
    required this.hasError,
    required this.onChanged,
    required this.onLinkTapped,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.inter(
      fontSize: 15,
      color: context.colors.textSecondary,
    );
    return InkWell(
      key: const Key('terms_agreement'),
      onTap: () => onChanged(!agreed),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            Transform.scale(
              scale: 1.3,
              child: Checkbox(
                value: agreed,
                activeColor: context.colors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.0),
                ),
                side: BorderSide(
                  color: hasError
                      ? const Color(0xFFDC2626)
                      : context.colors.iconSubtle,
                  width: 1.5,
                ),
                onChanged: (value) => onChanged(value ?? false),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(context.l10n.authAgreeToTermsPrefix, style: textStyle),
                  GestureDetector(
                    key: const Key('terms_link'),
                    onTap: onLinkTapped,
                    child: Text(
                      context.l10n.authTermsOfServices,
                      style: textStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colors.primary,
                        decoration: TextDecoration.underline,
                        decorationColor: context.colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
