import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';
import 'package:tilomnov/shared/utils/app_popup.dart';
import 'package:tilomnov/features/auth/presentation/screens/terms_of_service_page.dart';
import 'package:tilomnov/shared/transitions/app_page_route.dart';
import 'package:tilomnov/features/auth/presentation/view_models/login_controller.dart';
import 'package:tilomnov/features/auth/presentation/view_models/sign_up_form.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_providers.dart';
import '../widgets/create_account_form.dart';
import '../widgets/create_account_actions.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/auth/presentation/auth_error_message.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// Create an account screen for Tilomnov.
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
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  /// Problems are shown once the user has tried to sign up, and then follow
  /// what they type.
  bool _showProblems = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  SignUpForm get _form => SignUpForm(
    name: _nameController.text,
    phone: _phoneController.text,
    email: _emailController.text,
    password: _passwordController.text,
    agreedToTerms: _agreeToTerms,
  );

  String? _message(SignUpProblem? problem) {
    if (!_showProblems || problem == null) return null;
    final l10n = context.l10n;
    return switch (problem) {
      SignUpProblem.missingName => l10n.authErrEnterName,
      SignUpProblem.invalidPhone => l10n.authErrEnterValidPhone,
      SignUpProblem.invalidEmail => l10n.authErrEnterValidEmail,
      SignUpProblem.missingPassword => l10n.authErrEnterPassword,
      SignUpProblem.shortPassword => l10n.authErrPasswordMin8,
      SignUpProblem.termsNotAccepted => l10n.authErrAgreeTerms,
    };
  }

  Future<void> _handleSignUp() async {
    final form = _form;
    setState(() => _showProblems = true);
    if (!form.isValid) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authServiceProvider)
          .register(
            phone: form.normalizedPhone!,
            email: form.normalizedEmail,
            name: form.trimmedName,
            password: form.password,
          );

      if (widget.onSignUpPressed != null) {
        widget.onSignUpPressed!();
      } else if (mounted) {
        AppPopup.showSuccess(
          context,
          context.l10n.authAccountCreatedSuccessfullyPleaseLogin,
        );
        _navigateToLogin();
      }
    } catch (e) {
      if (mounted) {
        AppPopup.showError(context, authErrorMessage(context.l10n, e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Only for reading: ticking the box on the form is enough to agree.
  Future<void> _openTermsOfService() async {
    final agreed = await Navigator.of(context).push<bool>(
      AppPageRoute(page: TermsOfServicePage(initialAgreed: _agreeToTerms)),
    );
    if (agreed != null && mounted) setState(() => _agreeToTerms = agreed);
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
    final form = _form;
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
                      phoneController: _phoneController,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      nameError: _message(form.nameProblem),
                      phoneError: _message(form.phoneProblem),
                      emailError: _message(form.emailProblem),
                      passwordError: _message(form.passwordProblem),
                      termsError: _message(form.termsProblem),
                      obscurePassword: _obscurePassword,
                      agreeToTerms: _agreeToTerms,
                      onChanged: () {
                        if (_showProblems) setState(() {});
                      },
                      onTogglePasswordVisibility: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      onTermsChanged: (agreed) =>
                          setState(() => _agreeToTerms = agreed),
                      onTermsLinkTapped: _openTermsOfService,
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
