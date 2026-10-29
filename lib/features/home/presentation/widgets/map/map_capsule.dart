import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/home/presentation/providers/glass_navigation_provider.dart';
import 'package:tilomnov/features/home/presentation/widgets/glass/glass_surface.dart';

/// A rounded capsule floating over the map (the search bar, a filter pill):
/// glass where the navigation is glass, a solid surface otherwise, so these
/// match the round map buttons beside them.
///
/// [outline] rings the capsule, as the selected pill does. The ring takes the
/// same room whether or not it shows, so selecting never shifts the layout.
class MapCapsule extends ConsumerWidget {
  static const _radius = 24.0;
  static const _ringWidth = 1.5;

  final EdgeInsetsGeometry padding;
  final double? height;
  final Color? outline;

  /// Whether to reserve and draw the [outline] ring at all.
  final bool ring;
  final List<BoxShadow>? shadows;

  /// False for a capsule that casts no shadow at all, [shadows] included.
  final bool shadowed;
  final Widget child;

  const MapCapsule({
    super.key,
    required this.padding,
    required this.child,
    this.height,
    this.outline,
    this.ring = true,
    this.shadows,
    this.shadowed = true,
  });

  static final _defaultShadows = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glass = watchGlassNavigation(ref, context);
    final radius = BorderRadius.circular(_radius);
    // A plain DecoratedBox does not inset its child by its border.
    final content = Padding(
      padding: ring ? padding.add(const EdgeInsets.all(_ringWidth)) : padding,
      child: child,
    );
    final ringed = ring
        ? DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: outline ?? Colors.transparent,
                width: _ringWidth,
              ),
            ),
            child: content,
          )
        : content;

    final Widget capsule = glass
        ? GlassSurface(borderRadius: radius, shadow: shadowed, child: ringed)
        : DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: radius,
              boxShadow: shadowed ? shadows ?? _defaultShadows : null,
            ),
            child: ringed,
          );
    return height == null ? capsule : SizedBox(height: height, child: capsule);
  }
}
