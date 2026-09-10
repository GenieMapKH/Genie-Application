import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:genie/features/auth/data/repositories/auth_repository.dart';
import 'package:genie/core/errors/app_exceptions.dart';
import 'package:genie/shared/utils/app_popup.dart';
import 'package:genie/features/auth/presentation/screens/terms_of_service_page.dart';
import 'package:genie/shared/transitions/app_page_route.dart';
import 'package:genie/features/auth/presentation/view_models/login_controller.dart';
import 'package:genie/features/property/presentation/view_models/property_providers.dart';
import 'package:genie/features/profile/presentation/view_models/user_providers.dart';
import '../widgets/create_account_form.dart';
import '../widgets/create_account_actions.dart';

/// Create an account screen for Genie.
class CreateAccountPage extends ConsumerStatefulWidget {
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
  ConsumerState<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends ConsumerState<CreateAccountPage> {
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
      } else if (_passwordController.text.length < 8) {
        _passwordError = 'Password must be at least 8 characters';
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

  Future<void> _handleSignUp() async {
    final isValid = _validateForm();
    if (isValid) {
      setState(() => _isLoading = true);
      try {
        String identifier = _identifierController.text.trim();
        // Clean phone number if it's not an email
        if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(identifier)) {
          identifier = identifier.replaceAll(RegExp(r'[\s\-()]'), '');
        }

        await ref
            .read(authServiceProvider)
            .register(identifier, _passwordController.text);

        if (widget.onSignUpPressed != null) {
          widget.onSignUpPressed!();
        } else {
          if (mounted) {
            AppPopup.showSuccess(
              context,
              'Account created successfully! Please login.',
            );
            _navigateToLogin();
          }
        }
      } on AppException catch (e) {
        if (mounted) {
          AppPopup.showError(context, 'Registration failed: ${e.message}');
        }
      } catch (e) {
        if (mounted) {
          AppPopup.showError(context, 'An unexpected error occurred: $e');
        }
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
      context.go('/login');
    }
  }

  void _onAuthSuccess() {
    if (!mounted) return;
    AppPopup.showSuccess(context, 'Successfully authenticated!');
    ref.invalidate(userProfileProvider);
    ref.invalidate(propertiesProvider);
    ref.invalidate(publicPropertiesProvider);
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<bool>>(loginControllerProvider, (previous, next) {
      if (next.isLoading) return;

      if (next.hasError) {
        if (!mounted) return;
        final errorMessage = next.error is AppException
            ? (next.error as AppException).message
            : 'Authentication failed: ${next.error}';
        AppPopup.showError(context, errorMessage);
      } else if (next.hasValue && next.value == true) {
        if (!mounted) return;
        _onAuthSuccess();
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

                    CreateAccountForm(
                      nameController: _nameController,
                      identifierController: _identifierController,
                      passwordController: _passwordController,
                      nameError: _nameError,
                      identifierError: _identifierError,
                      passwordError: _passwordError,
                      termsError: _termsError,
                      obscurePassword: _obscurePassword,
                      agreeToTerms: _agreeToTerms,
                      onNameChanged: (val) {
                        if (_nameError != null && val.trim().isNotEmpty) {
                          setState(() => _nameError = null);
                        }
                      },
                      onIdentifierChanged: (val) {
                        if (_identifierError != null &&
                            _validateIdentifier(val)) {
                          setState(() => _identifierError = null);
                        }
                      },
                      onPasswordChanged: (val) {
                        if (_passwordError != null && val.length >= 6) {
                          setState(() => _passwordError = null);
                        }
                      },
                      onTogglePasswordVisibility: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      onTermsChanged: (val) {
                        if (val == true) {
                          _openTermsOfService();
                        } else {
                          setState(() {
                            _agreeToTerms = false;
                          });
                        }
                      },
                      onTermsTextTapped: () {
                        if (!_agreeToTerms) {
                          _openTermsOfService();
                        } else {
                          setState(() {
                            _agreeToTerms = false;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 28),

                    CreateAccountActions(
                      isLoading: _isLoading,
                      onSignUp: _handleSignUp,
                      onGoogleSignUp: () async {
                        if (widget.onGoogleSignUpPressed != null) {
                          widget.onGoogleSignUpPressed!();
                        } else {
                          final success = await ref
                              .read(loginControllerProvider.notifier)
                              .googleLogin(forceAccountSelection: true);
                          if (success && mounted) {
                            _onAuthSuccess();
                          }
                        }
                      },
                      onSignInHere: _navigateToLogin,
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
