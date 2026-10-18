import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genie/features/auth/data/repositories/auth_repository.dart';
import 'package:genie/shared/widgets/forms/app_text_field.dart';
import 'package:genie/shared/utils/app_popup.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  String? _emailError;
  bool _isLoading = false;

  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));
    _entryController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  bool _validateEmail(String value) {
    return RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(value.trim());
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();

    setState(() {
      _emailError = _validateEmail(email)
          ? null
          : 'Please enter a valid email address';
    });

    if (_emailError != null) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authServiceProvider).forgotPassword(email);
      if (!mounted) return;
      AppPopup.showSuccess(
        context,
        context.l10n.authVerificationCodeSentToYourEmail,
      );
      context.push('/verify-otp?email=${Uri.encodeComponent(email)}');
    } catch (e) {
      if (!mounted) return;
      AppPopup.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 24.0,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 408.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: context.colors.border),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            size: 20,
                            color: context.colors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Title
                      Text(
                        context.l10n.authForgotPassword,
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.authEnterYourEmailAddressToGet,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: context.colors.textMuted,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Email field
                      AppTextField(
                        label: context.l10n.authEmailAddress,
                        hintText: context.l10n.authExampleGmailCom,
                        controller: _emailController,
                        errorText: _emailError,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        onChanged: (val) {
                          if (_emailError != null) {
                            setState(() {
                              _emailError = _validateEmail(val)
                                  ? null
                                  : 'Please enter a valid email address';
                            });
                          }
                        },
                        onSubmitted: (_) => _handleSubmit(),
                      ),
                      const SizedBox(height: 32),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.colors.primary,
                            disabledBackgroundColor: context.colors.primary
                                .withValues(alpha: 0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: context.colors.onPrimary,
                                  ),
                                )
                              : Text(
                                  context.l10n.authPasswordReset,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: context.colors.onPrimary,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Create account link
                      Center(
                        child: GestureDetector(
                          onTap: () => context.go('/register'),
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
