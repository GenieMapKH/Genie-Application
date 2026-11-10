import 'package:flutter/material.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// The results-panel card of the listing the map was flown to: outlined, with
/// a "View property" button that opens its detail.
class FocusedListingCard extends StatelessWidget {
  final Widget child;
  final VoidCallback onView;

  const FocusedListingCard({
    super.key,
    required this.child,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.primary, width: 2),
            ),
          ),
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: FilledButton.icon(
            onPressed: onView,
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.open_in_full_rounded, size: 18),
            label: Text(context.l10n.searchViewProperty),
          ),
        ),
      ],
    );
  }
}
