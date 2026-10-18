import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:genie/features/auth/presentation/view_models/login_controller.dart';
import 'package:genie/features/auth/presentation/view_models/login_form_provider.dart';
import 'package:genie/shared/utils/app_popup.dart';
import 'package:genie/features/property/presentation/view_models/property_providers.dart';

import '../widgets/login_header.dart';
import '../widgets/login_form.dart';
import '../widgets/social_login_buttons.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/auth/presentation/auth_error_message.dart';
import 'package:genie/l10n/l10n.dart';

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

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
    Future.microtask(() {
      ref.read(loginControllerProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Called once per sign-in, by the listener in [build]. The user's own
  /// profile, listings and favourites follow the session by themselves.
  void _onAuthSuccess() {
    if (!mounted) return;
    AppPopup.showSuccess(context, context.l10n.authSuccessfullyLoggedIn);
    // The public feed may say what this user liked or saved.
    ref.invalidate(publicPropertiesProvider);
    if (GoRouter.maybeOf(context) != null) {
      context.go('/home');
    }
  }

  String? _fieldError(LoginFieldError? error) {
    final l10n = context.l10n;
    return switch (error) {
      LoginFieldError.invalidEmail => l10n.authErrEnterValidEmail,
      LoginFieldError.invalidPhone => l10n.authErrEnterValidPhone,
      LoginFieldError.missingPassword => l10n.authErrEnterPassword,
      LoginFieldError.shortPassword => l10n.authErrPasswordMin6,
      null => null,
    };
  }

  Future<void> _handleLogin() async {
    final success = await ref.read(loginFormProvider.notifier).submit();
    if (success && mounted) widget.onLoginPressed?.call();
  }

  Widget _buildAnimatedTabBar(AuthMethod selectedMethod) {
    final isEmail = selectedMethod == AuthMethod.email;

    return SizedBox(
      height: 34,
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  ref
                      .read(loginFormProvider.notifier)
                      .setMethod(AuthMethod.email);
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
                          ? context.colors.primary
                          : context.colors.textMuted,
                    ),
                    child: Text(context.l10n.personalInfoEmail),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: () {
                  ref
                      .read(loginFormProvider.notifier)
                      .setMethod(AuthMethod.phone);
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
                          ? context.colors.primary
                          : context.colors.textMuted,
                    ),
                    child: Text(context.l10n.authPhoneNumber),
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
                color: context.colors.primary,
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
    final formState = ref.watch(loginFormProvider);
    final formNotifier = ref.read(loginFormProvider.notifier);

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
                    LoginHeader(
                      slideAnimation: _headerSlide,
                      fadeAnimation: _headerFade,
                    ),
                    const SizedBox(height: 32),
                    _buildAnimatedTabBar(formState.selectedMethod),
                    const SizedBox(height: 24),
                    LoginForm(
                      slideAnimation: _formSlide,
                      fadeAnimation: _formFade,
                      selectedMethod: formState.selectedMethod,
                      emailController: _emailController,
                      phoneController: _phoneController,
                      passwordController: _passwordController,
                      emailError: _fieldError(formState.emailError),
                      phoneError: _fieldError(formState.phoneError),
                      passwordError: _fieldError(formState.passwordError),
                      obscurePassword: formState.obscurePassword,
                      keepMeSignedIn: formState.keepMeSignedIn,
                      onEmailChanged: (val) {
                        formNotifier.setEmail(val);
                      },
                      onPhoneChanged: (val) {
                        formNotifier.setPhone(val);
                      },
                      onPasswordChanged: (val) {
                        formNotifier.setPassword(val);
                      },
                      onTogglePasswordVisibility: () {
                        formNotifier.togglePasswordVisibility();
                      },
                      onKeepMeSignedInChanged: (val) {
                        formNotifier.setKeepMeSignedIn(val ?? false);
                      },
                      onForgotPasswordPressed: () {
                        if (widget.onForgotPasswordPressed != null) {
                          widget.onForgotPasswordPressed!();
                        } else {
                          context.push('/forgot-password');
                        }
                      },
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
                        } else if (!loginState.isLoading) {
                          // The listener in build reacts to the outcome.
                          ref
                              .read(loginControllerProvider.notifier)
                              .googleLogin();
                        }
                      },
                      onCreateAccount: () {
                        if (widget.onCreateAccountPressed != null) {
                          widget.onCreateAccountPressed!();
                        } else {
                          context.push('/register');
                        }
                      },
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
