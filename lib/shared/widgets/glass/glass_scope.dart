import 'package:flutter/widgets.dart';

import 'package:tilomnov/shared/widgets/glass/glass_surface.dart';

/// Whether the controls floating over the app's pages (back, call and share
/// buttons, the bars over photos) are drawn in glass ([GlassSurface]).
///
/// Set once above every page from the same setting as the glass navigation
/// bar, so shared widgets can ask without depending on a feature.
class GlassScope extends InheritedWidget {
  final bool enabled;

  const GlassScope({super.key, required this.enabled, required super.child});

  /// False where no scope is above (a test, a preview).
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GlassScope>()?.enabled ??
      false;

  @override
  bool updateShouldNotify(GlassScope oldWidget) => oldWidget.enabled != enabled;
}
