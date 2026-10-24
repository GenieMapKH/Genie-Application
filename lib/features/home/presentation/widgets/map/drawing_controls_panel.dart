import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genie/shared/widgets/buttons/tactile_button.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/shared/widgets/media/tinted_svg.dart';

class DrawingControlsPanel extends StatelessWidget {
  final bool isEditingPolygon;
  final VoidCallback onRevertPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback onCancelPressed;
  final VoidCallback onSavePressed;
  final VoidCallback onAddPinPressed;

  const DrawingControlsPanel({
    super.key,
    required this.isEditingPolygon,
    required this.onRevertPressed,
    required this.onDeletePressed,
    required this.onCancelPressed,
    required this.onSavePressed,
    required this.onAddPinPressed,
  });

  Widget _buildCircleButton(
    BuildContext context,
    String iconPath, {
    required VoidCallback onPressed,
  }) {
    return TactileButton(
      onPressed: onPressed,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: context.colors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: TintedSvg(
            iconPath,
            width: 24,
            height: 24,
            color: context.colors.textSecondary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Left Column: Revert and Delete
        Positioned(
          left: 16,
          bottom: 124, // Offset for extendBody
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {}, // Prevent taps from bleeding through to the map
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCircleButton(
                  context,
                  'assets/icons/revert.svg',
                  onPressed: onRevertPressed,
                ),
                const SizedBox(height: 12),
                _buildCircleButton(
                  context,
                  'assets/icons/bin.svg',
                  onPressed: onDeletePressed,
                ),
              ],
            ),
          ),
        ),
        // Bottom Center: Cancel and Save
        Positioned(
          bottom: 124, // Offset for extendBody
          left: 0,
          right: 0,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {}, // Prevent taps from bleeding through
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TactileButton(
                    onPressed: onCancelPressed,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 12.0,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: context.colors.border,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        context.l10n.commonCancel,
                        style: GoogleFonts.inter(
                          color: context.colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TactileButton(
                    onPressed: onSavePressed,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 12.0,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.accent,
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        context.l10n.commonSave,
                        style: GoogleFonts.inter(
                          color: context.colors.onPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Right Column: Add Pin (only if not editing)
        if (!isEditingPolygon)
          Positioned(
            right: 16,
            bottom: 124, // Offset for extendBody
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {}, // Prevent taps from bleeding through to the map
              child: TactileButton(
                onPressed: onAddPinPressed,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5484D),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE5484D).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_location_alt,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
