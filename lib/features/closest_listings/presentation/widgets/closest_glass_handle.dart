import 'package:flutter/material.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/closest_listings/presentation/closest_sheet_layout.dart';
import 'package:tilomnov/features/home/presentation/widgets/glass/glass_surface.dart';

/// The pull-up list's resting handle as a small pane of glass, drawn over
/// the sheet's top while the glass navigation bar is on. Fades out once the
/// sheet is pulled up and its opaque panel takes over.
///
/// Draws only: touches go through to the sheet's own handle underneath.
class ClosestGlassHandle extends StatelessWidget {
  /// Whether the sheet is pulled up.
  final bool raised;

  const ClosestGlassHandle({super.key, required this.raised});

  static const _width = 84.0;
  static const _height = 28.0;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: raised ? 0 : 1,
        duration: const Duration(milliseconds: 150),
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(
              top: (ClosestSheetLayout.peekHeight - _height) / 2,
            ),
            child: SizedBox(
              width: _width,
              height: _height,
              child: GlassSurface(
                borderRadius: BorderRadius.circular(_height / 2),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.colors.textMuted,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
