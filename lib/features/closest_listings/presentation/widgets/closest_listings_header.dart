import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/closest_listings/presentation/closest_sheet_layout.dart';
import 'package:tilomnov/features/closest_listings/presentation/view_models/closest_listings_provider.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// The top of the map's pull-up list: the handle that shows while it rests,
/// then what the list is and a button to measure again from the user.
class ClosestListingsHeader extends StatelessWidget {
  /// False until the sheet is first pulled up: nothing is read before.
  final bool opened;
  final double gutter;

  /// Tapping the handle pulls the sheet up or lets it down.
  final VoidCallback onHandleTap;

  const ClosestListingsHeader({
    super.key,
    required this.opened,
    required this.gutter,
    required this.onHandleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Handle(onTap: onHandleTap),
        Padding(
          padding: EdgeInsets.fromLTRB(gutter, 2, gutter - 8, 12),
          child: opened ? const _Title() : const _Title.resting(),
        ),
      ],
    );
  }
}

class _Handle extends StatelessWidget {
  final VoidCallback onTap;

  const _Handle({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.closestShowList,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: ClosestSheetLayout.peekHeight,
          child: Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Title extends ConsumerWidget {
  final bool _resting;

  const _Title() : _resting = false;

  /// Before anything was read: measured from the user, as it usually is.
  const _Title.resting() : _resting = true;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final listings = _resting ? null : ref.watch(closestListingsProvider);
    final nearUser = listings?.valueOrNull?.nearUser ?? true;
    final busy = listings != null && listings.isLoading && listings.hasValue;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nearUser ? l10n.closestTitleNearYou : l10n.closestTitleNearMap,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.closestSubtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
        ),
        if (busy)
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: colors.accent,
              ),
            ),
          )
        else
          IconButton(
            tooltip: l10n.closestRefresh,
            onPressed: _resting
                ? null
                : () => ref.read(closestListingsProvider.notifier).refresh(),
            icon: Icon(Icons.my_location_rounded, color: colors.accent),
          ),
      ],
    );
  }
}
