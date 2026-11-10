import 'package:flutter/material.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/feed/data/feed_filters.dart';
import 'package:tilomnov/features/home/presentation/widgets/map/filter/filter_number_field.dart';
import 'package:tilomnov/features/home/presentation/widgets/map/filter/filter_section.dart';
import 'package:tilomnov/features/property/presentation/property_labels.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// Changes stay in this sheet until applied; dismissing it preserves the feed.
class FeedFilterSheet extends StatefulWidget {
  final FeedFilters initial;

  const FeedFilterSheet({super.key, required this.initial});

  static Future<FeedFilters?> show(BuildContext context, FeedFilters initial) =>
      showModalBottomSheet<FeedFilters>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        backgroundColor: context.colors.surface,
        builder: (_) => FeedFilterSheet(initial: initial),
      );

  @override
  State<FeedFilterSheet> createState() => _FeedFilterSheetState();
}

class _FeedFilterSheetState extends State<FeedFilterSheet> {
  late FeedSort _sort = widget.initial.sort;
  late String? _type = widget.initial.propertyType;
  late double? _min = widget.initial.minPrice;
  late double? _max = widget.initial.maxPrice;
  late DateTimeRange? _dates =
      widget.initial.fromDate == null || widget.initial.toDate == null
      ? null
      : DateTimeRange(
          start: widget.initial.fromDate!,
          end: widget.initial.toDate!,
        );

  FeedFilters get _draft => FeedFilters(
    sort: _sort,
    propertyType: _type,
    minPrice: _min,
    maxPrice: _max,
    fromDate: _dates?.start,
    toDate: _dates?.end,
  );

  void _reset() => setState(() {
    _sort = FeedSort.newest;
    _type = null;
    _min = _max = null;
    _dates = null;
  });

  Future<void> _pickDates() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1970),
      lastDate: DateUtils.dateOnly(DateTime.now()),
      initialDateRange: _dates,
    );
    if (picked != null && mounted) setState(() => _dates = picked);
  }

  void _recentDays(int days) {
    final today = DateUtils.dateOnly(DateTime.now());
    setState(
      () => _dates = DateTimeRange(
        start: DateTime(today.year, today.month, today.day - days + 1),
        end: today,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final draft = _draft;
    final invalid = draft.priceRangeReversed || !draft.pricesValid;
    final dateLabels = MaterialLocalizations.of(context);
    final dates = _dates;
    final sortLabels = {
      FeedSort.newest: l10n.sortNewest,
      FeedSort.top: l10n.feedSortTop,
      FeedSort.priceLow: l10n.sortPriceLowToHigh,
      FeedSort.priceHigh: l10n.sortPriceHighToLow,
    };

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.85,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      l10n.filterTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: dateLabels.closeButtonTooltip,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                children: [
                  FilterSection(
                    title: l10n.propertySortBy,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final sort in FeedSort.values)
                          ChoiceChip(
                            showCheckmark: false,
                            label: Text(sortLabels[sort]!),
                            selected: _sort == sort,
                            onSelected: (_) => setState(() => _sort = sort),
                          ),
                      ],
                    ),
                  ),
                  FilterSection(
                    title: l10n.feedListingDate,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              showCheckmark: false,
                              label: Text(l10n.feedAnyTime),
                              selected: dates == null,
                              onSelected: (_) => setState(() => _dates = null),
                            ),
                            ActionChip(
                              label: Text(l10n.feedLast7Days),
                              onPressed: () => _recentDays(7),
                            ),
                            ActionChip(
                              label: Text(l10n.feedLast30Days),
                              onPressed: () => _recentDays(30),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: _pickDates,
                          icon: const Icon(Icons.date_range_outlined),
                          label: Text(
                            dates == null
                                ? l10n.feedChooseDates
                                : '${dateLabels.formatCompactDate(dates.start)} – ${dateLabels.formatCompactDate(dates.end)}',
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilterSection(
                    title: '${l10n.filterPriceRange} (USD)',
                    child: FilterFieldPair(
                      firstLabel: l10n.filterMinPrice,
                      secondLabel: l10n.filterMaxPrice,
                      errorText: draft.priceRangeReversed
                          ? l10n.filterMinAboveMax
                          : !draft.pricesValid
                          ? l10n.feedPriceInvalid
                          : null,
                      first: FilterNumberField(
                        hint: l10n.filterNoMin,
                        value: _min,
                        hasError: invalid,
                        onChanged: (value) => setState(() => _min = value),
                      ),
                      second: FilterNumberField(
                        hint: l10n.filterNoMax,
                        value: _max,
                        hasError: invalid,
                        onChanged: (value) => setState(() => _max = value),
                      ),
                    ),
                  ),
                  FilterSection(
                    title: l10n.filterPropertyType,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final type in [
                          'Land',
                          'House',
                          'Building',
                          'Condo',
                          'Borey',
                          'Business for Sale',
                          'Warehouse',
                        ])
                          FilterChip(
                            showCheckmark: false,
                            label: Text(propertyValueLabel(l10n, type)),
                            selected: _type == type,
                            onSelected: (selected) =>
                                setState(() => _type = selected ? type : null),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 48),
                        ),
                        onPressed: _reset,
                        child: Text(l10n.filterReset),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 48),
                        ),
                        onPressed: invalid
                            ? null
                            : () => Navigator.of(context).pop(_draft),
                        child: Text(l10n.filterSeeResults),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
