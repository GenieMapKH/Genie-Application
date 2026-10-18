import 'dart:async';
import 'package:flutter/material.dart';
import 'package:genie/features/auth/presentation/screens/welcome_page.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/shared/widgets/media/app_logo.dart';

/// A modern, responsive splash/loading page displaying the Genie core logo.
/// Seamlessly transitions to [WelcomePage] after a brief splash display.
class LoadingPage extends StatefulWidget {
  final Duration displayDuration;
  final VoidCallback? onFinished;

  const LoadingPage({
    super.key,
    this.displayDuration = const Duration(milliseconds: 1400),
    this.onFinished,
  });

  static const double logoWidth = 220.0;
  static const double logoHeight = 150.0;

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.displayDuration > Duration.zero) {
      _timer = Timer(widget.displayDuration, _proceedToNext);
    }
  }

  void _proceedToNext() {
    if (!mounted) return;
    if (widget.onFinished != null) {
      widget.onFinished!();
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 700),
          pageBuilder: (context, animation, secondaryAnimation) =>
              const WelcomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Center(
          child: ScaleTransition(
            scale: _pulseAnimation,
            child: Hero(
              tag: 'genie_core_logo',
              child: AppLogo(
                width: LoadingPage.logoWidth,
                height: LoadingPage.logoHeight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
