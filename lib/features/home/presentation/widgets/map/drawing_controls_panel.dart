import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tilomnov/shared/widgets/buttons/tactile_button.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/media/tinted_svg.dart';

class DrawingControlsPanel extends StatelessWidget {
  /// The buttons' distance from the screen's bottom. The nav bar is hidden
  /// while drawing, so they sit just above the system's own bottom inset.
  static double _bottomOf(BuildContext context) =>
      MediaQuery.viewPaddingOf(context).bottom + 24;

  /// How far up from the screen's bottom the buttons hide the map: the
  /// action labels can wrap or stack on narrow screens.
  static double coveredBottomOf(BuildContext context) =>
      _bottomOf(context) +
      math.max(
        108,
        _actionHeight(context) * (_stackActions(context) ? 2 : 1) +
            (_stackActions(context) ? 12 : 0),
      );

  static bool _stackActions(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 400 ||
      MediaQuery.textScalerOf(context).scale(16) > 20;

  static double _actionHeight(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width - 32 - 48 - 24 - 64;
    final labelWidth = _stackActions(context) ? width : (width - 12) / 2;
    final painter = TextPainter(
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    );
    var height = 48.0;
    for (final label in [context.l10n.commonCancel, context.l10n.commonSave]) {
      painter.text = TextSpan(
        text: label,
        style: DefaultTextStyle.of(context).style.merge(
          GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );
      painter.layout(maxWidth: math.max(1, labelWidth - 18));
      height = math.max(height, painter.height + 26);
    }
    painter.dispose();
    return height;
  }

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

  Widget _action(
    BuildContext context,
    String label,
    VoidCallback onPressed, {
    bool primary = false,
  }) {
    return TactileButton(
      onPressed: onPressed,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: primary ? context.colors.accent : context.colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: primary ? null : Border.all(color: context.colors.border),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: primary
                ? context.colors.onPrimary
                : context.colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stacked = _stackActions(context);
    final cancel = _action(context, context.l10n.commonCancel, onCancelPressed);
    final save = _action(
      context,
      context.l10n.commonSave,
      onSavePressed,
      primary: true,
    );
    return Stack(
      children: [
        Positioned(
          left: 16,
          right: 16,
          bottom: _bottomOf(context),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {}, // Keep control taps from reaching the map.
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
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
                const SizedBox(width: 12),
                Expanded(
                  child: stacked
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [cancel, const SizedBox(height: 12), save],
                        )
                      : Row(
                          children: [
                            Expanded(child: cancel),
                            const SizedBox(width: 12),
                            Expanded(child: save),
                          ],
                        ),
                ),
                if (!isEditingPolygon) ...[
                  const SizedBox(width: 12),
                  Tooltip(
                    message: context.l10n.homeAddPoint,
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
                              color: const Color(
                                0xFFE5484D,
                              ).withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          LucideIcons.mapPinPlusInside,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
