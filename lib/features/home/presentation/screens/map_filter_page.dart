import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/home/presentation/providers/map_filter_draft_provider.dart';
import 'package:genie/features/home/presentation/widgets/map/filter/filter_number_field.dart';
import 'package:genie/features/home/presentation/widgets/map/filter/filter_section.dart';
import 'package:genie/features/home/presentation/widgets/map/filter/keyword_filter_chips.dart';
import 'package:genie/features/home/presentation/widgets/map/filter/listing_scope_tabs.dart';
import 'package:genie/features/home/presentation/widgets/map/filter/price_range_section.dart';
import 'package:genie/features/property/presentation/view_models/map_property_filter.dart';
import 'package:genie/features/property/presentation/widgets/property_type_selector.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/shared/utils/app_popup.dart';

/// Everything the map can be narrowed by. Choices stay on this page until
/// "See results" puts them on the map; going back drops them.
class MapFilterPage extends ConsumerStatefulWidget {
  const MapFilterPage({super.key});

  @override
  ConsumerState<MapFilterPage> createState() => _MapFilterPageState();
}

class _MapFilterPageState extends ConsumerState<MapFilterPage> {
  /// Counted up by Reset, to empty the down payment box too.
  int _resets = 0;

  MapFilterDraftNotifier get _draft =>
      ref.read(mapFilterDraftProvider.notifier);

  void _reset() {
    _draft.reset();
    setState(() => _resets++);
  }

  void _seeResults() {
    if (_draft.apply()) {
      Navigator.of(context).pop();
    } else {
      AppPopup.showError(context, context.l10n.filterMinAboveMax);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(mapFilterDraftProvider);
    final l10n = context.l10n;
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.filterTitle,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
          ListingScopeTabs(filter: filter, onSelected: _draft.selectListing),
          const SizedBox(height: 20),
          PriceRangeSection(filter: filter),
          if (!filter.isForRent) _downPayment(context),
          _size(context, filter),
          FilterSection(
            title: l10n.filterPropertyType,
            child: PropertyTypeSelector(
              selectedPropertyType: filter.propertyType ?? '',
              onChanged: _draft.toggleType,
            ),
          ),
          FilterSection(
            title: l10n.filterKeywords,
            child: KeywordFilterChips(
              selected: filter.keywords,
              onToggle: _draft.toggleKeyword,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _FilterActions(
        onReset: _reset,
        onSeeResults: _seeResults,
      ),
    );
  }

  /// Listings carry no down payment yet: the box is shown, as designed, but
  /// filters nothing until they do.
  Widget _downPayment(BuildContext context) {
    return FilterSection(
      title: context.l10n.filterDownPayment,
      child: FilterNumberField(
        key: ValueKey(_resets),
        hint: context.l10n.filterNoDownPayment,
        value: null,
        onChanged: (_) {},
      ),
    );
  }

  Widget _size(BuildContext context, MapPropertyFilter filter) {
    final l10n = context.l10n;
    final invalid = MapFilterDraftNotifier.sizeRangeInvalid(filter);
    return FilterSection(
      title: filter.propertyType == 'Land'
          ? l10n.filterLandSize
          : l10n.filterPropertySize,
      child: FilterFieldPair(
        errorText: invalid ? l10n.filterMinAboveMax : null,
        first: FilterNumberField(
          hint: l10n.filterMinArea,
          value: filter.minSize,
          hasError: invalid,
          onChanged: (min) => _draft.setSize(min, filter.maxSize),
        ),
        second: FilterNumberField(
          hint: l10n.filterMaxArea,
          value: filter.maxSize,
          hasError: invalid,
          onChanged: (max) => _draft.setSize(filter.minSize, max),
        ),
      ),
    );
  }
}

class _FilterActions extends StatelessWidget {
  final VoidCallback onReset;
  final VoidCallback onSeeResults;

  const _FilterActions({required this.onReset, required this.onSeeResults});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    );
    final label = GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: colors.background,
          border: Border(top: BorderSide(color: colors.divider)),
        ),
        child: Row(
          children: [
            OutlinedButton(
              onPressed: onReset,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.textPrimary,
                side: BorderSide(color: colors.border),
                shape: shape,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
              ),
              child: Text(context.l10n.filterReset, style: label),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: onSeeResults,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  elevation: 0,
                  shape: shape,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(context.l10n.filterSeeResults, style: label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
