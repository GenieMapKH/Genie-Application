import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/core/device/glass_capability.dart';
import 'package:tilomnov/core/device/reduce_transparency.dart';
import 'package:tilomnov/features/settings/providers/app_settings_providers.dart';

/// Whether the navigation bar and the map's buttons are drawn in glass: only
/// on phones whose own interface is glass, while the user keeps it on and
/// has not asked the system for less transparency. Widgets ask through
/// [watchGlassNavigation], which also respects increased contrast.
final glassNavigationOnProvider = Provider<bool>(
  (ref) =>
      ref.watch(glassCapableDeviceProvider) &&
      ref.watch(glassNavigationProvider) &&
      !ref.watch(reduceTransparencyProvider),
);

/// [glassNavigationOnProvider], unless the screen asks for more contrast:
/// text over glass is then harder to read than over a solid surface.
bool watchGlassNavigation(WidgetRef ref, BuildContext context) =>
    ref.watch(glassNavigationOnProvider) && !MediaQuery.highContrastOf(context);
