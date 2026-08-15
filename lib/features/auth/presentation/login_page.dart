import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genie/features/auth/presentation/create_account_page.dart';
import 'package:genie/shared/transitions/app_page_route.dart';
import 'package:genie/shared/widgets/app_button.dart';
import 'package:genie/shared/widgets/app_text_field.dart';
import 'package:genie/shared/widgets/google_icon.dart';

enum AuthMethod { email, phone }

/// Login screen supporting Email and Phone Number authentication methods,
/// Google OAuth login, "Keep me signed in" preference, and custom error states.
class LoginPage extends StatefulWidget {
  final VoidCallback? onLoginPressed;
  final VoidCallback? onGoogleLoginPressed;
  final VoidCallback? onForgotPasswordPressed;
  final VoidCallback? onCreateAccountPressed;

  const LoginPage({
    super.key,
    this.onLoginPressed,
    this.onGoogleLoginPressed,
    this.onForgotPasswordPressed,
    this.onCreateAccountPressed,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  AuthMethod _selectedMethod = AuthMethod.email;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _emailError;
  String? _phoneError;
  String? _passwordError;

  bool _obscurePassword = true;
  bool _keepMeSignedIn = true;
  bool _isLoading = false;

  late AnimationController _entryController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _formFade;
  late Animation<Offset> _formSlide;
  late Animation<double> _actionsFade;
  late Animation<Offset> _actionsSlide;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _formFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _actionsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _actionsSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validateEmail(String value) {
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
    return emailRegex.hasMatch(value.trim());
  }

  bool _validatePhone(String value) {
    final clean = value.replaceAll(RegExp(r'[\s\-()]'), '');
    final phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');
    return phoneRegex.hasMatch(clean);
  }

  bool _validateForm() {
    var isValid = true;

    setState(() {
      if (_selectedMethod == AuthMethod.email) {
        if (!_validateEmail(_emailController.text)) {
          _emailError = 'Enter a valid email address';
          isValid = false;
        } else {
          _emailError = null;
        }
      } else {
        if (!_validatePhone(_phoneController.text)) {
          _phoneError = 'Enter a valid phone number';
          isValid = false;
        } else {
          _phoneError = null;
        }
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
    });

    return isValid;
  }

  void _handleLogin() {
    final isValid = _validateForm();
    if (isValid && widget.onLoginPressed != null) {
      setState(() => _isLoading = true);
      try {
        widget.onLoginPressed!();
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 408.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),

                    // Header with animated entrance
                    RepaintBoundary(
                      child: SlideTransition(
                        position: _headerSlide,
                        child: FadeTransition(
                          opacity: _headerFade,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Login',
                                style: GoogleFonts.inter(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E293B),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Welcome back to the app',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Auth Method Tabs with Sliding Underline Indicator
                    RepaintBoundary(
                      child: SlideTransition(
                        position: _headerSlide,
                        child: FadeTransition(
                          opacity: _headerFade,
                          child: _buildAnimatedTabBar(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Form Fields with Directional Slide & Fade Transition
                    RepaintBoundary(
                      child: SlideTransition(
                        position: _formSlide,
                        child: FadeTransition(
                          opacity: _formFade,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 240),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                transitionBuilder: (child, animation) {
                                  final isEmail =
                                      child.key == const Key('email_field');
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
                                child: _selectedMethod == AuthMethod.email
                                    ? AppTextField(
                                        key: const Key('email_field'),
                                        label: 'Email Address',
                                        hintText: 'example@gmail.com',
                                        errorText: _emailError,
                                        controller: _emailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        onChanged: (val) {
                                          if (_emailError != null) {
                                            setState(() {
                                              _emailError = _validateEmail(val)
                                                  ? null
                                                  : 'Enter a valid email address';
                                            });
                                          }
                                        },
                                      )
                                    : AppTextField(
                                        key: const Key('phone_field'),
                                        label: 'Phone number',
                                        hintText: 'Phone number',
                                        errorText: _phoneError,
                                        controller: _phoneController,
                                        keyboardType: TextInputType.phone,
                                        textInputAction: TextInputAction.next,
                                        onChanged: (val) {
                                          if (_phoneError != null) {
                                            setState(() {
                                              _phoneError = _validatePhone(val)
                                                  ? null
                                                  : 'Enter a valid phone number';
                                            });
                                          }
                                        },
                                      ),
                              ),
                              const SizedBox(height: 20),

                              // Password Field with "Forget Password?" link & Error handling
                              AppTextField(
                                key: const Key('password_field'),
                                label: 'Password',
                                hintText: '••••••••••••',
                                errorText: _passwordError,
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onChanged: (val) {
                                  if (_passwordError != null) {
                                    setState(() {
                                      if (val.isEmpty) {
                                        _passwordError = 'Enter a valid password';
                                      } else if (val.length < 6) {
                                        _passwordError =
                                            'Password must be at least 6 characters';
                                      } else {
                                        _passwordError = null;
                                      }
                                    });
                                  }
                                },
                                topTrailingWidget: GestureDetector(
                                  onTap: widget.onForgotPasswordPressed ?? () {},
                                  child: Text(
                                    'Forget Password?',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF4F5BD5),
                                    ),
                                  ),
                                ),
                                suffixIcon: IconButton(
                                  icon: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    transitionBuilder: (child, animation) =>
                                        ScaleTransition(
                                      scale: animation,
                                      child: child,
                                    ),
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

                              // Keep me signed in Checkbox
                              Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _keepMeSignedIn,
                                      activeColor: const Color(0xFF4F5BD5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(4.0),
                                      ),
                                      side: const BorderSide(
                                        color: Color(0xFFCBD5E1),
                                        width: 1.5,
                                      ),
                                      onChanged: (val) {
                                        setState(() {
                                          _keepMeSignedIn = val ?? false;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _keepMeSignedIn = !_keepMeSignedIn;
                                      });
                                    },
                                    child: Text(
                                      'Keep me signed in',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: const Color(0xFF4B5563),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Actions Section with staggered entrance
                    RepaintBoundary(
                      child: SlideTransition(
                        position: _actionsSlide,
                        child: FadeTransition(
                          opacity: _actionsFade,
                          child: Column(
                            children: [
                              // Primary Login Button (#4F5BD5)
                              AppButton.primary(
                                text: 'Login',
                                isLoading: _isLoading,
                                onPressed: _handleLogin,
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
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0),
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

                              // Google OAuth Login Button
                              AppButton(
                                text: 'Continue with Google',
                                backgroundColor: Colors.white,
                                textColor: const Color(0xFF1F2937),
                                borderColor: const Color(0xFFE5E7EB),
                                borderWidth: 1.5,
                                icon: const GoogleIcon(size: 20),
                                onPressed: widget.onGoogleLoginPressed ?? () {},
                              ),
                              const SizedBox(height: 54),

                              // Bottom Link: Create a Account
                              Center(
                                child: GestureDetector(
                                  onTap: widget.onCreateAccountPressed ??
                                      () {
                                        Navigator.of(context).pushReplacement(
                                          AppPageRoute(
                                            page: const CreateAccountPage(),
                                            direction: SlideDirection.fromLeft,
                                          ),
                                        );
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
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTabBar() {
    final isEmail = _selectedMethod == AuthMethod.email;

    return SizedBox(
      height: 34,
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (_selectedMethod != AuthMethod.email) {
                    setState(() {
                      _selectedMethod = AuthMethod.email;
                      _phoneError = null;
                    });
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: isEmail ? FontWeight.w600 : FontWeight.w500,
                      color: isEmail
                          ? const Color(0xFF4F5BD5)
                          : const Color(0xFF64748B),
                    ),
                    child: const Text('Email'),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: () {
                  if (_selectedMethod != AuthMethod.phone) {
                    setState(() {
                      _selectedMethod = AuthMethod.phone;
                      _emailError = null;
                    });
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: !isEmail ? FontWeight.w600 : FontWeight.w500,
                      color: !isEmail
                          ? const Color(0xFF4F5BD5)
                          : const Color(0xFF64748B),
                    ),
                    child: const Text('Phone Number'),
                  ),
                ),
              ),
            ],
          ),

          // Sliding Underline Indicator
          AnimatedPositioned(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            left: isEmail ? 0 : 64.0,
            bottom: 0,
            width: isEmail ? 40.0 : 110.0,
            height: 2.0,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF4F5BD5),
                borderRadius: BorderRadius.circular(1.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
