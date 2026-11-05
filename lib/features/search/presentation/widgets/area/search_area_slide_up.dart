import 'package:flutter/material.dart';

/// Rises and fades in once when it first appears.
class SearchAreaSlideUp extends StatelessWidget {
  final Widget child;

  const SearchAreaSlideUp({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: const Cubic(0.16, 1.0, 0.3, 1.0),
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: FractionalTranslation(
          translation: Offset(0, (1 - t) * 0.08),
          child: child,
        ),
      ),
    );
  }
}
