import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/features/home/presentation/providers/glass_navigation_provider.dart';
import 'package:tilomnov/features/home/presentation/widgets/layout/classic_bottom_nav.dart';
import 'package:tilomnov/features/home/presentation/widgets/layout/glass_bottom_nav.dart';

/// The bottom navigation: a floating glass capsule on phones whose own
/// interface is glass, the regular bar everywhere else.
class MainBottomNav extends ConsumerWidget {
  const MainBottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return watchGlassNavigation(ref, context)
        ? const GlassBottomNav()
        : const ClassicBottomNav();
  }
}
