import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_visibility.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// The buttons along the bottom of a My Properties card: change the
/// listing's status, open its insights, and show it on the map.
class PropertyCardActions extends StatelessWidget {
  final String status;
  final VoidCallback onStatusTapped;
  final VoidCallback onInsightsTapped;

  /// No map button when null (the listing has no place on the map).
  final VoidCallback? onViewOnMap;

  const PropertyCardActions({
    super.key,
    required this.status,
    required this.onStatusTapped,
    required this.onInsightsTapped,
    this.onViewOnMap,
  });

  @override
  Widget build(BuildContext context) {
    // A listing being paid for can be moved nowhere until that settles.
    final canChangeStatus = PropertyVisibility.values.any(
      (target) => visibilityChange(status, target) != null,
    );
    return Row(
      children: [
        Expanded(
          child: _CardActionButton(
            icon: SvgPicture.asset('assets/icons/listing_visibility.svg'),
            label: context.l10n.propertyVisibility,
            onPressed: canChangeStatus ? onStatusTapped : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CardActionButton(
            icon: SvgPicture.asset('assets/icons/listing_insights.svg'),
            label: context.l10n.insightsTitle,
            onPressed: onInsightsTapped,
          ),
        ),
        if (onViewOnMap case final onViewOnMap?) ...[
          const SizedBox(width: 8),
          Tooltip(
            message: context.l10n.propertyViewOnMap,
            child: _CardActionButton(
              icon: const Icon(LucideIcons.map, size: 18),
              onPressed: onViewOnMap,
            ),
          ),
        ],
      ],
    );
  }
}

class _CardActionButton extends StatelessWidget {
  final Widget icon;

  /// Null draws a square, icon-only button.
  final String? label;
  final VoidCallback? onPressed;

  const _CardActionButton({
    required this.icon,
    this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final label = this.label;
    if (label == null) {
      return OutlinedButton(
        onPressed: onPressed,
        style: _style(context).copyWith(
          minimumSize: const WidgetStatePropertyAll(Size.square(36)),
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        ),
        child: icon,
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: SizedBox.square(dimension: 16, child: icon),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      style: _style(context),
    );
  }

  ButtonStyle _style(BuildContext context) {
    return OutlinedButton.styleFrom(
      foregroundColor: context.colors.accent,
      disabledForegroundColor: context.colors.textHint,
      side: BorderSide(color: context.colors.border),
      minimumSize: const Size.fromHeight(36),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
