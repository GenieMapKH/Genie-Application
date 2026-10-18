import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genie/features/auth/data/repositories/auth_repository.dart';
import 'package:genie/shared/widgets/forms/app_text_field.dart';
import 'package:genie/shared/utils/app_popup.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/auth/presentation/auth_error_message.dart';
import 'package:genie/l10n/l10n.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  final String email;
  final String otp;

  const ResetPasswordPage({super.key, required this.email, required this.otp});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage>
    with SingleTickerProviderStateMixin {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _passwordError;
  String? _confirmPasswordError;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  bool _validate() {
    bool isValid = true;

    setState(() {
      if (_passwordController.text.isEmpty) {
        _passwordError = context.l10n.authErrEnterNewPassword;
        isValid = false;
      } else if (_passwordController.text.length < 8) {
        _passwordError = context.l10n.authErrPasswordMin8;
        isValid = false;
      } else {
        _passwordError = null;
      }

      if (_confirmPasswordController.text.isEmpty) {
        _confirmPasswordError = context.l10n.authErrReEnterPassword;
        isValid = false;
      } else if (_confirmPasswordController.text != _passwordController.text) {
        _confirmPasswordError = context.l10n.authErrPasswordsDontMatch;
        isValid = false;
      } else {
        _confirmPasswordError = null;
      }
    });

    return isValid;
  }

  Future<void> _handleReset() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authServiceProvider)
          .resetPassword(widget.email, widget.otp, _passwordController.text);
      if (!mounted) return;
      AppPopup.showSuccess(
        context,
        context.l10n.authPasswordResetSuccessfullyPleaseLogIn,
      );
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      AppPopup.showError(context, authErrorMessage(context.l10n, e));
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
                        context.l10n.authResetPassword,
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.authEnterYourNewPasswordTwiceBelow,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: context.colors.textMuted,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // New password
                      AppTextField(
                        label: context.l10n.authEnterNewPassword,
                        hintText: '123!@#\$%',
                        controller: _passwordController,
                        errorText: _passwordError,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        suffixIcon: GestureDetector(
                          onTap: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          child: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: context.colors.textHint,
                            size: 22,
                          ),
                        ),
                        onChanged: (val) {
                          if (_passwordError != null) {
                            setState(() {
                              if (val.isEmpty) {
                                _passwordError =
                                    context.l10n.authErrEnterNewPassword;
                              } else if (val.length < 8) {
                                _passwordError =
                                    context.l10n.authErrPasswordMin8;
                              } else {
                                _passwordError = null;
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // Confirm password
                      AppTextField(
                        label: context.l10n.authReEnterNewPassword,
                        hintText: '••••••••',
                        controller: _confirmPasswordController,
                        errorText: _confirmPasswordError,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        suffixIcon: GestureDetector(
                          onTap: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                          child: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: context.colors.textHint,
                            size: 22,
                          ),
                        ),
                        onChanged: (val) {
                          if (_confirmPasswordError != null) {
                            setState(() {
                              if (val != _passwordController.text) {
                                _confirmPasswordError =
                                    context.l10n.authErrPasswordsDontMatch;
                              } else {
                                _confirmPasswordError = null;
                              }
                            });
                          }
                        },
                        onSubmitted: (_) => _handleReset(),
                      ),
                      const SizedBox(height: 32),

                      // Reset button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleReset,
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
                                  context.l10n.authResetPassword,
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
