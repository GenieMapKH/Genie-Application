import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:genie/core/network/api_client.dart';
import 'package:genie/core/storage/auth_storage.dart';
import 'package:genie/features/auth/presentation/create_account_page.dart';
import 'package:genie/features/auth/presentation/login_page.dart';
import 'package:genie/shared/transitions/app_page_route.dart';
import 'package:genie/shared/widgets/app_button.dart';
import 'package:genie/features/home/presentation/main_layout.dart';

/// Optimized, high-performance Welcome / Auth landing screen.
///
/// Features a hardware-accelerated, stutter-free splash-to-welcome entrance animation:
/// 1. Holds logo centered briefly.
/// 2. Glides logo upwards smoothly.
/// 3. Staggered fade and slide for headlines, buttons, and bottom action links.
class WelcomePage extends StatefulWidget {
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

  static const String logoAssetPath = 'assets/images/login/image.png';

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
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
  late final TextStyle _headlineStyle;
  late final TextStyle _subtitleStyle;
  late final TextStyle _createAccountStyle;

  @override
  void initState() {
    super.initState();

    _headlineStyle = GoogleFonts.inter(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF1E293B),
      letterSpacing: -0.5,
    );

    _subtitleStyle = GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF64748B),
      height: 1.4,
    );

    _createAccountStyle = GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF4F5BD5),
    );

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
      backgroundColor: Colors.white,
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
                        child: Image.asset(
                          WelcomePage.logoAssetPath,
                          width: 114.0,
                          height: 159.0,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                        ),
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
                              'Welcome to the app',
                              style: _headlineStyle,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20.0,
                              ),
                              child: Text(
                                'Find and share properties with exact map location',
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
                            text: 'Login',
                            onPressed:
                                widget.onLoginPressed ??
                                () {
                                  Navigator.of(
                                    context,
                                  ).push(AppPageRoute(page: const LoginPage()));
                                },
                          ),
                          const SizedBox(height: 10),

                          // Explore without account Secondary Button (#E5E7EB)
                          AppButton.secondary(
                            text: 'Explore without account',
                            onPressed:
                                widget.onExplorePressed ??
                                () async {
                                  try {
                                    // Guest session initialization
                                    String? guestId = await AuthStorage.getGuestSessionId();
                                    if (guestId == null) {
                                      final timestamp = DateTime.now().millisecondsSinceEpoch;
                                      final random = math.Random().nextInt(1000000);
                                      guestId = 'guest_${timestamp}_$random';
                                      await AuthStorage.saveGuestSessionId(guestId);
                                    }
                                    
                                    // Register with backend
                                    final dio = createApiClient();
                                    await dio.post(
                                      '/public/properties/guest-session', 
                                      data: {'deviceId': guestId}
                                    );
                                  } catch (e) {
                                    debugPrint('Guest session init failed: $e');
                                  }
                                  
                                  if (context.mounted) {
                                    Navigator.of(context).pushReplacement(
                                      AppPageRoute(page: const MainLayout()),
                                    );
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
                                    Navigator.of(context).push(
                                      AppPageRoute(
                                        page: const CreateAccountPage(),
                                      ),
                                    );
                                  },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Create a Account',
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
