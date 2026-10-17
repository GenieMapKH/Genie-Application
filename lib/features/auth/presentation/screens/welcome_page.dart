import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genie/features/auth/data/repositories/auth_repository.dart';
import 'package:genie/features/home/presentation/providers/main_nav_provider.dart';
import 'package:genie/shared/widgets/app_button.dart';
import 'package:genie/shared/widgets/app_logo.dart';
import 'package:go_router/go_router.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';

/// Optimized, high-performance Welcome / Auth landing screen.
///
/// Features a hardware-accelerated, stutter-free splash-to-welcome entrance animation:
/// 1. Holds logo centered briefly.
/// 2. Glides logo upwards smoothly.
/// 3. Staggered fade and slide for headlines, buttons, and bottom action links.
class WelcomePage extends ConsumerStatefulWidget {
  final VoidCallback? onLoginPressed;
  final VoidCallback? onExplorePressed;
  final VoidCallback? onCreateAccountPressed;
  final Duration splashDelay;
  final Duration animationDuration;
  final bool autoStart;

  const WelcomePage({
    super.key,
    this.onLoginPressed,
    this.onExplorePressed,
    this.onCreateAccountPressed,
    this.splashDelay = const Duration(milliseconds: 600),
    this.animationDuration = const Duration(milliseconds: 800),
    this.autoStart = true,
  });

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _delayTimer;

  late Animation<Offset> _logoSlideAnimation;
  late Animation<double> _logoScaleAnimation;

  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;

  late Animation<double> _buttonsFadeAnimation;
  late Animation<Offset> _buttonsSlideAnimation;

  late Animation<double> _createAccountFadeAnimation;

  // Cached text styles to avoid runtime lookups during animation frames
  late TextStyle _headlineStyle;
  late TextStyle _subtitleStyle;
  late TextStyle _createAccountStyle;

  /// The styles use theme colours, which cannot be read in [initState] and
  /// change when the user switches between light and dark.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _headlineStyle = GoogleFonts.inter(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: context.colors.textPrimary,
      letterSpacing: -0.5,
    );

    _subtitleStyle = GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: context.colors.textMuted,
      height: 1.4,
    );

    _createAccountStyle = GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: context.colors.primary,
    );
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    // Logo glides up from center (offset 0.35 -> 0.0)
    _logoSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
          ),
        );

    _logoScaleAnimation = Tween<double>(begin: 1.08, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    // Headline & Subtitle fade and upward slide
    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.20, 0.70, curve: Curves.easeOut),
      ),
    );

    _headerSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.20, 0.70, curve: Curves.easeOutCubic),
          ),
        );

    // Buttons section fade and upward slide
    _buttonsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.85, curve: Curves.easeOut),
      ),
    );

    _buttonsSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.30), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.40, 0.85, curve: Curves.easeOutCubic),
          ),
        );

    // Create a Account text link fade
    _createAccountFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.60, 1.0, curve: Curves.easeOut),
      ),
    );

    if (widget.autoStart) {
      if (widget.splashDelay > Duration.zero) {
        _delayTimer = Timer(widget.splashDelay, () {
          if (mounted) _controller.forward();
        });
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Hardware-isolated Logo & Headline Section
              RepaintBoundary(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SlideTransition(
                      position: _logoSlideAnimation,
                      child: ScaleTransition(
                        scale: _logoScaleAnimation,
                        child: const AppLogo(width: 220.0, height: 150.0),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SlideTransition(
                      position: _headerSlideAnimation,
                      child: FadeTransition(
                        opacity: _headerFadeAnimation,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              context.l10n.authWelcomeToTheApp,
                              style: _headlineStyle,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20.0,
                              ),
                              child: Text(
                                context
                                    .l10n
                                    .authFindAndSharePropertiesWithExact,
                                style: _subtitleStyle,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),

              // Hardware-isolated Buttons Section
              RepaintBoundary(
                child: SlideTransition(
                  position: _buttonsSlideAnimation,
                  child: FadeTransition(
                    opacity: _buttonsFadeAnimation,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Login Primary Button (#4F5BD5)
                          AppButton.primary(
                            text: context.l10n.authLogin,
                            onPressed:
                                widget.onLoginPressed ??
                                () {
                                  context.push('/login');
                                },
                          ),
                          const SizedBox(height: 10),

                          // Explore without account Secondary Button (#E5E7EB)
                          AppButton.secondary(
                            text: context.l10n.authExploreWithoutAccount,
                            onPressed:
                                widget.onExplorePressed ??
                                () async {
                                  await ref
                                      .read(authServiceProvider)
                                      .ensureGuestSession();

                                  ref
                                      .read(mainNavProvider.notifier)
                                      .resetToHome();

                                  if (context.mounted) {
                                    context.go('/home');
                                  }
                                },
                          ),
                          const SizedBox(height: 24),

                          // Create a Account text link (#4F5BD5)
                          FadeTransition(
                            opacity: _createAccountFadeAnimation,
                            child: GestureDetector(
                              onTap:
                                  widget.onCreateAccountPressed ??
                                  () {
                                    context.push('/register');
                                  },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  context.l10n.authCreateAAccount,
                                  style: _createAccountStyle,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
