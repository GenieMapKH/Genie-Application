import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/home/presentation/providers/glass_navigation_provider.dart';
import 'package:tilomnov/features/home/presentation/widgets/glass/glass_surface.dart';
import 'package:tilomnov/features/home/presentation/widgets/map/map_button_icon.dart';
import 'package:tilomnov/features/home/presentation/widgets/utm/utm_locate_bottom_sheet.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/buttons/tactile_button.dart';
import 'package:tilomnov/shared/widgets/media/tinted_svg.dart';

/// The map's round buttons on the right, one tap each: enter coordinates,
/// draw a boundary, and go to the current position.
class MapSideButtons extends StatelessWidget {
  final VoidCallback onDrawPressed;
  final void Function(List<LatLng>) onCoordinatesScanned;
  final VoidCallback onGoToCurrentPosition;

  /// Distance from the bottom of the screen. Raised while the property card
  /// or a results sheet is on screen so the buttons clear it.
  final double bottom;

  /// Width of each button, the same as the current-position artwork.
  final double buttonSize;

  const MapSideButtons({
    super.key,
    required this.onDrawPressed,
    required this.onCoordinatesScanned,
    required this.onGoToCurrentPosition,
    required this.bottom,
    required this.buttonSize,
  });

  Future<void> _enterCoordinates(BuildContext context) async {
    final result = await showModalBottomSheet<List<LatLng>>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: false,
      backgroundColor: Colors.transparent,
      builder: (context) => const UtmLocateBottomSheet(),
    );
    if (result != null && result.isNotEmpty && context.mounted) {
      onCoordinatesScanned(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: const Cubic(0.16, 1.0, 0.3, 1.0),
      right: 0,
      bottom: bottom,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {}, // Prevent taps from bleeding to the map
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MapDiscButton(
              asset: 'assets/icons/utm.svg',
              tooltip: context.l10n.homeCoordinates,
              width: buttonSize,
              onPressed: () => _enterCoordinates(context),
            ),
            const SizedBox(height: _MapDiscButton.gap),
            _MapDiscButton(
              asset: 'assets/icons/draw.svg',
              tooltip: context.l10n.homeDraw,
              width: buttonSize,
              onPressed: onDrawPressed,
            ),
            // Its artwork leaves [_MapDiscButton.gap] above its disc.
            TactileButton(
              onPressed: onGoToCurrentPosition,
              child: MapButtonIcon(
                asset: 'assets/icons/current_position.svg',
                width: buttonSize,
                height: buttonSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A round button drawn like [MapButtonIcon]'s artwork (a 44 px disc with a
/// 2 px ring, 16 px in from the left of a 76 px box) for a plain glyph, so it
/// lines up with and matches the current-position button, in glass where
/// the navigation is glass.
class _MapDiscButton extends ConsumerWidget {
  static const _disc = 44.0;
  static const _ring = 2.0;
  static const _glyph = 20.0;

  /// The space between two discs, as the artwork leaves above its own.
  static const gap = 12.0;

  final String asset;
  final String tooltip;
  final double width;
  final VoidCallback onPressed;

  const _MapDiscButton({
    required this.asset,
    required this.tooltip,
    required this.width,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final glass = watchGlassNavigation(ref, context);
    final glyph = TintedSvg(
      asset,
      width: _glyph,
      height: _glyph,
      color: glass ? colors.textPrimary : colors.textMuted,
    );
    return Tooltip(
      message: tooltip,
      child: TactileButton(
        onPressed: onPressed,
        child: SizedBox(
          width: width,
          height: _disc,
          child: Center(
            child: SizedBox.square(
              dimension: _disc,
              child: glass
                  ? GlassSurface(
                      borderRadius: BorderRadius.circular(_disc / 2),
                      child: Center(child: glyph),
                    )
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.border, width: _ring),
                      ),
                      child: Center(child: glyph),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
