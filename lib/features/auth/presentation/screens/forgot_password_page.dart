import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tilomnov/features/auth/presentation/view_models/password_reset_flow.dart';
import 'package:tilomnov/features/auth/presentation/widgets/auth_back_button.dart';
import 'package:tilomnov/shared/widgets/forms/app_text_field.dart';
import 'package:tilomnov/shared/utils/app_popup.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/auth/presentation/auth_error_message.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// "Forgot password": recovery through the account's email.
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

  Future<void> _handleSubmit() => _sendEmailCode();

  Future<void> _sendEmailCode() async {
    final email = _emailController.text.trim();
    setState(() {
      _emailError = _validateEmail(email)
          ? null
          : context.l10n.authErrEnterEmail;
    });
    if (_emailError != null) return;

    await _withLoading(() async {
      final target = await ref
          .read(passwordResetFlowProvider)
          .sendEmailCode(email);
      if (!mounted) return;
      AppPopup.showSuccess(
        context,
        context.l10n.authVerificationCodeSentToYourEmail,
      );
      context.push('/verify-otp', extra: target);
    }, errorText: (e) => authErrorMessage(context.l10n, e));
  }

  Future<void> _withLoading(
    Future<void> Function() action, {
    required String Function(Object error) errorText,
  }) async {
    setState(() => _isLoading = true);
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      AppPopup.showError(context, errorText(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _addressField() => AppTextField(
    key: const Key('reset_email_field'),
    label: context.l10n.authEmailAddress,
    hintText: context.l10n.authExampleGmailCom,
    controller: _emailController,
    errorText: _emailError,
    keyboardType: TextInputType.emailAddress,
    textInputAction: TextInputAction.done,
    onSubmitted: (_) => _handleSubmit(),
  );

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
                      const AuthBackButton(),
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
                        context.l10n.authRecoveryEmailOnly,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: context.colors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _addressField(),
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
