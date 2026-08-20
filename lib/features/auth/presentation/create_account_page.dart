import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genie/features/auth/presentation/login_page.dart';
import 'package:genie/features/auth/presentation/terms_of_service_page.dart';
import 'package:genie/shared/transitions/app_page_route.dart';
import 'package:genie/shared/widgets/app_button.dart';
import 'package:genie/shared/widgets/app_text_field.dart';
import 'package:genie/shared/widgets/google_icon.dart';

/// Create an account screen for Genie.
class CreateAccountPage extends StatefulWidget {
  final VoidCallback? onSignUpPressed;
  final VoidCallback? onGoogleSignUpPressed;
  final VoidCallback? onSignInHerePressed;

  const CreateAccountPage({
    super.key,
    this.onSignUpPressed,
    this.onGoogleSignUpPressed,
    this.onSignInHerePressed,
  });

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _nameError;
  String? _identifierError;
  String? _passwordError;
  String? _termsError;

  bool _obscurePassword = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validateIdentifier(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;

    // Check email
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
    if (emailRegex.hasMatch(trimmed)) return true;

    // Check phone
    final cleanPhone = trimmed.replaceAll(RegExp(r'[\s\-()]'), '');
    final phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');
    return phoneRegex.hasMatch(cleanPhone);
  }

  bool _validateForm() {
    var isValid = true;

    setState(() {
      if (_nameController.text.trim().isEmpty) {
        _nameError = 'Please enter your name';
        isValid = false;
      } else {
        _nameError = null;
      }

      if (!_validateIdentifier(_identifierController.text)) {
        _identifierError = 'Enter a valid email address or phone number';
        isValid = false;
      } else {
        _identifierError = null;
      }

      if (_passwordController.text.isEmpty) {
        _passwordError = 'Enter a valid password';
        isValid = false;
      } else if (_passwordController.text.length < 6) {
        _passwordError = 'Password must be at least 6 characters';
        isValid = false;
      } else {
        _passwordError = null;
      }

      if (!_agreeToTerms) {
        _termsError = 'Please agree to the terms of services to continue.';
        isValid = false;
      } else {
        _termsError = null;
      }
    });

    return isValid;
  }

  void _handleSignUp() {
    final isValid = _validateForm();
    if (isValid && widget.onSignUpPressed != null) {
      setState(() => _isLoading = true);
      try {
        widget.onSignUpPressed!();
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openTermsOfService() async {
    final agreed = await Navigator.of(context).push<bool>(
      AppPageRoute(
        page: TermsOfServicePage(
          initialAgreed: _agreeToTerms,
          onAgreeChanged: (val) {
            setState(() {
              _agreeToTerms = val;
              if (val) _termsError = null;
            });
          },
        ),
      ),
    );

    if (agreed == true && mounted) {
      setState(() {
        _agreeToTerms = true;
        _termsError = null;
      });
    }
  }

  void _navigateToLogin() {
    if (widget.onSignInHerePressed != null) {
      widget.onSignInHerePressed!();
    } else {
      Navigator.of(context).pushReplacement(
        AppPageRoute(
          page: const LoginPage(),
          direction: SlideDirection.fromLeft,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 24.0,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 408.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),

                    // Header
                    Text(
                      'Create an account',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Name Field
                    AppTextField(
                      key: const Key('name_field'),
                      label: 'Name',
                      hintText: 'Username',
                      errorText: _nameError,
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      onChanged: (val) {
                        if (_nameError != null && val.trim().isNotEmpty) {
                          setState(() => _nameError = null);
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Email Address or Phone number Field
                    AppTextField(
                      key: const Key('identifier_field'),
                      label: 'Email Address or Phone number',
                      hintText: 'example@gmail.com',
                      errorText: _identifierError,
                      controller: _identifierController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onChanged: (val) {
                        if (_identifierError != null &&
                            _validateIdentifier(val)) {
                          setState(() => _identifierError = null);
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Password Field
                    AppTextField(
                      key: const Key('password_field'),
                      label: 'Password',
                      hintText: '••••••••••••',
                      errorText: _passwordError,
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onChanged: (val) {
                        if (_passwordError != null && val.length >= 6) {
                          setState(() => _passwordError = null);
                        }
                      },
                      suffixIcon: IconButton(
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            key: ValueKey<bool>(_obscurePassword),
                            color: const Color(0xFF64748B),
                            size: 20,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
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
                            value: _agreeToTerms,
                            activeColor: const Color(0xFF4F5BD5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            side: BorderSide(
                              color: _termsError != null
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFFCBD5E1),
                              width: 1.5,
                            ),
                            onChanged: (val) {
                              if (val == true) {
                                _openTermsOfService();
                              } else {
                                setState(() {
                                  _agreeToTerms = false;
                                });
                              }
                            },
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
                                  onTap: () {
                                    if (!_agreeToTerms) {
                                      _openTermsOfService();
                                    } else {
                                      setState(() {
                                        _agreeToTerms = false;
                                      });
                                    }
                                  },
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
                                  onTap: _openTermsOfService,
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

                    if (_termsError != null)
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
                                _termsError!,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: const Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 28),

                    // Primary Sign up Button (#4F5BD5)
                    AppButton.primary(
                      key: const Key('sign_up_button'),
                      text: 'Sign up',
                      isLoading: _isLoading,
                      onPressed: _handleSignUp,
                    ),
                    const SizedBox(height: 24),

                    // Divider: "or sign in with"
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(
                            color: Color(0xFFE5E7EB),
                            thickness: 1,
                          ),
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
                          child: Divider(
                            color: Color(0xFFE5E7EB),
                            thickness: 1,
                          ),
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
                      onPressed: widget.onGoogleSignUpPressed ?? () {},
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
                            onTap: _navigateToLogin,
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
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
