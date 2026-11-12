import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_visibility.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/feedback/failure_message.dart';

/// Lets the owner pick Public, Draft or Sold for a listing now of [status].
/// Resolves after saving the choice, or null when dismissed. Unavailable
/// choices are shown disabled, with why.
class PropertyVisibilitySheet extends StatefulWidget {
  final String status;
  final Future<void> Function(PropertyVisibility) onChanged;
  final Future<bool> Function()? onPaymentRequired;

  const PropertyVisibilitySheet({
    super.key,
    required this.status,
    required this.onChanged,
    this.onPaymentRequired,
  });

  static Future<PropertyVisibility?> show(
    BuildContext context,
    String status, {
    required Future<void> Function(PropertyVisibility) onChanged,
    Future<bool> Function()? onPaymentRequired,
  }) {
    return showModalBottomSheet<PropertyVisibility>(
      context: context,
      useRootNavigator: true,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PropertyVisibilitySheet(
        status: status,
        onChanged: onChanged,
        onPaymentRequired: onPaymentRequired,
      ),
    );
  }

  @override
  State<PropertyVisibilitySheet> createState() =>
      _PropertyVisibilitySheetState();
}

class _PropertyVisibilitySheetState extends State<PropertyVisibilitySheet> {
  PropertyVisibility? _saving;
  Object? _error;

  Future<void> _save(PropertyVisibility value) async {
    if (_saving != null) return;
    setState(() {
      _saving = value;
      _error = null;
    });
    try {
      try {
        await widget.onChanged(value);
      } on DioException catch (error) {
        if (error.response?.statusCode != 402 ||
            widget.onPaymentRequired == null) {
          rethrow;
        }
        if (!mounted) return;
        if (!await widget.onPaymentRequired!()) {
          if (mounted) setState(() => _saving = null);
          return;
        }
      }
      if (!mounted) return;
      setState(() => _saving = null);
      Navigator.of(context).pop(value);
    } catch (error, stack) {
      AppLogger.error('Changing listing visibility failed', error, stack);
      if (!mounted) return;
      setState(() {
        _saving = null;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    final current = PropertyVisibility.of(status);
    final l10n = context.l10n;

    Widget option(
      PropertyVisibility value,
      Widget icon,
      String title,
      String hint,
    ) {
      final isCurrent = value == current;
      final allowed = visibilityChange(status, value) != null;
      final reason = !isCurrent && !allowed && value == PropertyVisibility.sold
          ? l10n.propertyVisibilitySoldNeedsPublic
          : hint;
      final color = isCurrent || allowed
          ? context.colors.textPrimary
          : context.colors.textHint;

      return ListTile(
        enabled: allowed && _saving == null,
        leading: icon,
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        subtitle: Text(
          reason,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: context.colors.textMuted,
          ),
        ),
        trailing: _saving == value
            ? const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : isCurrent
            ? Icon(Icons.check_circle, color: context.colors.accent)
            : null,
        onTap: () => _save(value),
      );
    }

    return PopScope(
      canPop: _saving == null,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  l10n.propertyVisibility,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                  ),
                ),
              ),
              option(
                PropertyVisibility.public,
                const Icon(Icons.public),
                l10n.propertyVisibilityPublic,
                l10n.propertyVisibilityPublicHint,
              ),
              option(
                PropertyVisibility.draft,
                SvgPicture.asset(
                  'assets/icons/listing_draft.svg',
                  width: 24,
                  height: 24,
                ),
                l10n.propertyVisibilityDraft,
                l10n.propertyVisibilityDraftHint,
              ),
              option(
                PropertyVisibility.sold,
                SvgPicture.asset(
                  'assets/icons/listing_sold.svg',
                  width: 24,
                  height: 24,
                ),
                l10n.propertyVisibilitySold,
                l10n.propertyVisibilitySoldHint,
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    failureMessage(
                      l10n,
                      error: _error,
                      fallback: l10n.propertyCouldNotChangeVisibility,
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
