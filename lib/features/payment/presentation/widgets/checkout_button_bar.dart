import 'package:flutter/material.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/shared/widgets/buttons/tactile_button.dart';

/// The pay button pinned at the bottom of a checkout screen. Pale and inert
/// until a payment method is picked ([onPressed] null), then lit in the
/// brand colour; a spinner while the payment is under way.
class CheckoutButtonBar extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isBusy;

  const CheckoutButtonBar({
    super.key,
    required this.label,
    required this.onPressed,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final lit = onPressed != null || isBusy;
    final foreground = lit ? colors.onPrimary : colors.textMuted;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: TactileButton(
          onPressed: isBusy ? null : onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: lit ? colors.primary : colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: lit ? colors.primary : colors.border,
                width: 1.2,
              ),
              boxShadow: lit
                  ? [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : const [],
            ),
            child: isBusy
                ? SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: foreground,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: foreground,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
