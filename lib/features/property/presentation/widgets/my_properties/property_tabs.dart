import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/property/presentation/view_models/own_listings_tab.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/glass/glass_scope.dart';
import 'package:tilomnov/shared/widgets/glass/glass_surface.dart';

/// The user's listings counted by status, one tab per [OwnListingsTab];
/// tapping one shows its listings. With glass, one glass capsule with the
/// selected status lit inside it, as iOS draws a segmented control.
class PropertyTabs extends StatelessWidget {
  /// How many of the user's listings are in each status, loaded or not.
  final Map<String, int> countByStatus;
  final OwnListingsTab selected;
  final ValueChanged<OwnListingsTab> onSelected;

  const PropertyTabs({
    super.key,
    required this.countByStatus,
    required this.selected,
    required this.onSelected,
  });

  String _getTabTitle(BuildContext context, OwnListingsTab tab) {
    final l10n = context.l10n;
    final count = tab.countIn(countByStatus);
    return switch (tab) {
      OwnListingsTab.active => l10n.propertyTabActive(count),
      OwnListingsTab.pending => l10n.propertyTabPending(count),
      OwnListingsTab.draft => l10n.propertyTabDraft(count),
      OwnListingsTab.sold => l10n.propertyTabSold(count),
    };
  }

  /// [child] as a button choosing [tab].
  Widget _tappable(OwnListingsTab tab, Widget child) {
    return Semantics(
      button: true,
      selected: tab == selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: tab == selected ? null : () => onSelected(tab),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (GlassScope.of(context)) return _glass(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          for (final tab in OwnListingsTab.values) ...[
            if (tab.index > 0) const SizedBox(width: 8),
            Expanded(child: _tappable(tab, _buildTab(context, tab))),
          ],
        ],
      ),
    );
  }

  Widget _glass(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GlassSurface(
        borderRadius: BorderRadius.circular(22),
        shadow: false,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              for (final tab in OwnListingsTab.values)
                Expanded(child: _tappable(tab, _buildGlassTab(context, tab))),
            ],
          ),
        ),
      ),
    );
  }

  /// The selected tab is lit on the glass (never glass on glass).
  Widget _buildGlassTab(BuildContext context, OwnListingsTab tab) {
    final isSelected = tab == selected;
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected
            ? colors.textPrimary.withValues(alpha: 0.14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        _getTabTitle(context, tab),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? colors.textPrimary : colors.textMuted,
        ),
      ),
    );
  }

  Widget _buildTab(BuildContext context, OwnListingsTab tab) {
    final isSelected = tab == selected;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? context.colors.textPrimary : context.colors.divider,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getTabTitle(context, tab),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected
              ? context.colors.background
              : context.colors.textMuted,
        ),
      ),
    );
  }
}
