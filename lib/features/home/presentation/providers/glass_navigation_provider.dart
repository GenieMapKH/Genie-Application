import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/core/device/reduce_transparency.dart';
import 'package:tilomnov/features/settings/providers/app_settings_providers.dart';

/// Glass is the default on every device unless the user selects Minimalistic
/// or asks the system for less transparency. Widgets ask through
/// [watchGlassNavigation], which also respects increased contrast.
final glassNavigationOnProvider = Provider<bool>(
  (ref) =>
      ref.watch(glassNavigationProvider) &&
      !ref.watch(reduceTransparencyProvider),
);

/// [glassNavigationOnProvider], unless the screen asks for more contrast:
/// text over glass is then harder to read than over a solid surface.
bool watchGlassNavigation(WidgetRef ref, BuildContext context) =>
    ref.watch(glassNavigationOnProvider) && !MediaQuery.highContrastOf(context);

/// [watchGlassNavigation] outside of build, without listening.
bool readGlassNavigation(WidgetRef ref, BuildContext context) =>
    ref.read(glassNavigationOnProvider) && !MediaQuery.highContrastOf(context);
