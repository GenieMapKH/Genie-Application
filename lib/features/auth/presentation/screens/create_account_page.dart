import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:genie/features/auth/data/repositories/auth_repository.dart';
import 'package:genie/shared/utils/app_popup.dart';
import 'package:genie/features/auth/presentation/screens/terms_of_service_page.dart';
import 'package:genie/shared/transitions/app_page_route.dart';
import 'package:genie/features/auth/presentation/view_models/login_controller.dart';
import 'package:genie/features/property/presentation/view_models/property_providers.dart';
import '../widgets/create_account_form.dart';
import '../widgets/create_account_actions.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/auth/presentation/auth_error_message.dart';
import 'package:genie/l10n/l10n.dart';

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
        _nameError = context.l10n.authErrEnterName;
        isValid = false;
      } else {
        _nameError = null;
      }

      if (!_validateIdentifier(_identifierController.text)) {
        _identifierError = context.l10n.authErrEnterEmailOrPhone;
        isValid = false;
      } else {
        _identifierError = null;
      }

      if (_passwordController.text.isEmpty) {
        _passwordError = context.l10n.authErrEnterPassword;
        isValid = false;
      } else if (_passwordController.text.length < 8) {
        _passwordError = context.l10n.authErrPasswordMin8;
        isValid = false;
      } else {
        _passwordError = null;
      }

      if (!_agreeToTerms) {
        _termsError = context.l10n.authErrAgreeTerms;
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
              context.l10n.authAccountCreatedSuccessfullyPleaseLogin,
            );
            _navigateToLogin();
          }
        }
      } catch (e) {
        if (mounted) {
          AppPopup.showError(context, authErrorMessage(context.l10n, e));
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

  /// Called once per sign-in, by the listener in [build]. The user's own
  /// profile, listings and favourites follow the session by themselves.
  void _onAuthSuccess() {
    if (!mounted) return;
    AppPopup.showSuccess(context, context.l10n.authSuccessfullyAuthenticated);
    // The public feed may say what this user liked or saved.
    ref.invalidate(publicPropertiesProvider);
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<bool>>(loginControllerProvider, (previous, next) {
      if (next.isLoading) return;
      // Login and sign-up can both be open (one pushed over the other) and
      // share this controller: only the page in front answers, once.
      if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? true)) return;

      if (next.hasError) {
        if (!mounted) return;
        AppPopup.showError(
          context,
          authErrorMessage(context.l10n, next.error!),
        );
      } else if (next.hasValue && next.value == true) {
        if (!mounted) return;
        _onAuthSuccess();
      }
    });

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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),

                    // Header
                    Text(
                      context.l10n.authCreateAnAccount,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
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
                      onGoogleSignUp: () {
                        if (widget.onGoogleSignUpPressed != null) {
                          widget.onGoogleSignUpPressed!();
                        } else if (!ref
                            .read(loginControllerProvider)
                            .isLoading) {
                          // The listener in build reacts to the outcome.
                          ref
                              .read(loginControllerProvider.notifier)
                              .googleLogin(forceAccountSelection: true);
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
