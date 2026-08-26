import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/app_text_field.dart';

class CreateAccountForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController identifierController;
  final TextEditingController passwordController;
  final String? nameError;
  final String? identifierError;
  final String? passwordError;
  final String? termsError;
  final bool obscurePassword;
  final bool agreeToTerms;
  final Function(String) onNameChanged;
  final Function(String) onIdentifierChanged;
  final Function(String) onPasswordChanged;
  final VoidCallback onTogglePasswordVisibility;
  final Function(bool?) onTermsChanged;
  final VoidCallback onTermsTextTapped;

  const CreateAccountForm({
    super.key,
    required this.nameController,
    required this.identifierController,
    required this.passwordController,
    this.nameError,
    this.identifierError,
    this.passwordError,
    this.termsError,
    required this.obscurePassword,
    required this.agreeToTerms,
    required this.onNameChanged,
    required this.onIdentifierChanged,
    required this.onPasswordChanged,
    required this.onTogglePasswordVisibility,
    required this.onTermsChanged,
    required this.onTermsTextTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name Field
        AppTextField(
          key: const Key('name_field'),
          label: 'Name',
          hintText: 'Username',
          errorText: nameError,
          controller: nameController,
          textInputAction: TextInputAction.next,
          onChanged: onNameChanged,
        ),
        const SizedBox(height: 20),

        // Email Address or Phone number Field
        AppTextField(
          key: const Key('identifier_field'),
          label: 'Email Address or Phone number',
          hintText: 'example@gmail.com',
          errorText: identifierError,
          controller: identifierController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onChanged: onIdentifierChanged,
        ),
        const SizedBox(height: 20),

        // Password Field
        AppTextField(
          key: const Key('password_field'),
          label: 'Password',
          hintText: '••••••••••••',
          errorText: passwordError,
          controller: passwordController,
          obscureText: obscurePassword,
          textInputAction: TextInputAction.done,
          onChanged: onPasswordChanged,
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
                color: const Color(0xFF64748B),
                size: 20,
              ),
            ),
            onPressed: onTogglePasswordVisibility,
          ),
        ),
        const SizedBox(height: 16),

        // Terms of Service Checkbox
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: agreeToTerms,
                activeColor: const Color(0xFF4F5BD5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.0),
                ),
                side: BorderSide(
                  color: termsError != null
                      ? const Color(0xFFDC2626)
                      : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
                onChanged: onTermsChanged,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: onTermsTextTapped,
                      child: Text(
                        'By continuing, you agree to out ',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onTermsTextTapped,
                      child: Text(
                        'terms of services.',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4F5BD5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        if (termsError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6.0, left: 4.0),
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
