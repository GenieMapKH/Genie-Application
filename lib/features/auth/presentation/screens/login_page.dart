import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:genie/features/auth/presentation/view_models/login_controller.dart';
import 'package:genie/core/errors/app_exceptions.dart';
import 'package:genie/shared/utils/app_popup.dart';
import 'package:genie/features/property/presentation/view_models/property_providers.dart';
import 'package:genie/features/profile/presentation/view_models/user_providers.dart';

import '../widgets/login_header.dart';
import '../widgets/login_form.dart';
import '../widgets/social_login_buttons.dart';

enum AuthMethod { email, phone }

/// Login screen supporting Email and Phone Number authentication methods,
/// Google OAuth login, "Keep me signed in" preference, and custom error states.
class LoginPage extends ConsumerStatefulWidget {
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
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
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

    _headerSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
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

    _formSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(
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

    _actionsSlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(
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

  Future<void> _handleLogin() async {
    final isValid = _validateForm();
    if (isValid) {
      if (_selectedMethod == AuthMethod.email) {
        await ref
            .read(loginControllerProvider.notifier)
            .login(_emailController.text.trim(), _passwordController.text);
      } else {
        final cleanPhone = _phoneController.text.replaceAll(
          RegExp(r'[\s\-()]'),
          '',
        );
        await ref
            .read(loginControllerProvider.notifier)
            .login(cleanPhone, _passwordController.text);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginControllerProvider);

    ref.listen<AsyncValue<void>>(loginControllerProvider, (_, state) {
      if (!state.isLoading && state.hasError) {
        final errorMessage = state.error is AppException
            ? (state.error as AppException).message
            : 'Login failed. Please check your credentials and try again.';
        AppPopup.showError(context, errorMessage);
      } else if (!state.isLoading && !state.hasError && state.hasValue) {
        AppPopup.showSuccess(context, 'Successfully logged in!');
        ref.invalidate(userProfileProvider);
        ref.invalidate(propertiesProvider);
        ref.invalidate(publicPropertiesProvider);

        if (widget.onLoginPressed != null) {
          widget.onLoginPressed!();
        } else {
          context.go('/home');
        }
      }
    });

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
                    LoginHeader(
                      slideAnimation: _headerSlide,
                      fadeAnimation: _headerFade,
                    ),
                    const SizedBox(height: 32),
                    _buildAnimatedTabBar(),
                    const SizedBox(height: 24),
                    LoginForm(
                      slideAnimation: _formSlide,
                      fadeAnimation: _formFade,
                      selectedMethod: _selectedMethod,
                      emailController: _emailController,
                      phoneController: _phoneController,
                      passwordController: _passwordController,
                      emailError: _emailError,
                      phoneError: _phoneError,
                      passwordError: _passwordError,
                      obscurePassword: _obscurePassword,
                      keepMeSignedIn: _keepMeSignedIn,
                      onEmailChanged: (val) {
                        if (_emailError != null) {
                          setState(() {
                            _emailError = _validateEmail(val)
                                ? null
                                : 'Enter a valid email address';
                          });
                        }
                      },
                      onPhoneChanged: (val) {
                        if (_phoneError != null) {
                          setState(() {
                            _phoneError = _validatePhone(val)
                                ? null
                                : 'Enter a valid phone number';
                          });
                        }
                      },
                      onPasswordChanged: (val) {
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
                      onTogglePasswordVisibility: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      onKeepMeSignedInChanged: (val) {
                        setState(() {
                          _keepMeSignedIn = val ?? false;
                        });
                      },
                      onForgotPasswordPressed: widget.onForgotPasswordPressed,
                    ),
                    const SizedBox(height: 28),
                    LoginActions(
                      slideAnimation: _actionsSlide,
                      fadeAnimation: _actionsFade,
                      isLoading: loginState.isLoading,
                      onLogin: _handleLogin,
                      onGoogleLogin: () {
                        if (widget.onGoogleLoginPressed != null) {
                          widget.onGoogleLoginPressed!();
                        } else {
                          ref
                              .read(loginControllerProvider.notifier)
                              .googleLogin();
                        }
                      },
                      onCreateAccount: widget.onCreateAccountPressed,
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
}
