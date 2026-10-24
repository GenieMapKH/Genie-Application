import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/home/presentation/providers/map_filter_draft_provider.dart';
import 'package:genie/features/home/presentation/widgets/map/filter/filter_number_field.dart';
import 'package:genie/features/home/presentation/widgets/map/filter/filter_section.dart';
import 'package:genie/features/home/presentation/widgets/map/filter/price_range_slider.dart';
import 'package:genie/features/property/presentation/view_models/map_property_filter.dart';
import 'package:genie/features/property/utils/property_format.dart';
import 'package:genie/l10n/l10n.dart';

/// Price range: histogram and slider, then Min / Max Price boxes. The slider
/// and the boxes edit the same range.
class PriceRangeSection extends ConsumerStatefulWidget {
  final MapPropertyFilter filter;

  const PriceRangeSection({super.key, required this.filter});

  @override
  ConsumerState<PriceRangeSection> createState() => _PriceRangeSectionState();
}

class _PriceRangeSectionState extends ConsumerState<PriceRangeSection> {
  /// The bars last shown, kept while the next ones load so they don't blink.
  List<int> _counts = const [];

  void _setPrice(double? min, double? max) =>
      ref.read(mapFilterDraftProvider.notifier).setPrice(min, max);

  @override
  Widget build(BuildContext context) {
    final filter = widget.filter;
    final scale = MapPriceScale.of(filter);
    final unpriced = filter.withPrice(null, null);

    ref.listen(mapPriceHistogramProvider(unpriced), (_, next) {
      if (next case AsyncError(:final error, :final stackTrace)) {
        // The bars only decorate the slider: it works without them.
        AppLogger.error(
          'Loading the price histogram failed',
          error,
          stackTrace,
        );
      }
    });
    final latest = ref.watch(mapPriceHistogramProvider(unpriced)).valueOrNull;
    if (latest != null) _counts = latest;

    final l10n = context.l10n;
    final invalid = MapFilterDraftNotifier.priceRangeInvalid(filter);
    String withUnit(String price) =>
        scale.perMonth ? l10n.filterPerMonth(price) : price;

    return FilterSection(
      title: l10n.filterPriceRange,
      child: Column(
        children: [
          PriceRangeSlider(
            scale: scale,
            min: filter.minPrice,
            max: filter.maxPrice,
            counts: _counts,
            onChanged: _setPrice,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ScaleEnd(PropertyFormat.shortMoney(0)),
              _ScaleEnd(withUnit('${PropertyFormat.shortMoney(scale.top)}+')),
            ],
          ),
          const SizedBox(height: 16),
          FilterFieldPair(
            firstLabel: l10n.filterMinPrice,
            secondLabel: l10n.filterMaxPrice,
            errorText: invalid ? l10n.filterMinAboveMax : null,
            first: FilterNumberField(
              hint: l10n.filterNoMin,
              value: filter.minPrice,
              hasError: invalid,
              onChanged: (min) => _setPrice(min, filter.maxPrice),
            ),
            second: FilterNumberField(
              hint: l10n.filterNoMax,
              value: filter.maxPrice,
              hasError: invalid,
              onChanged: (max) => _setPrice(filter.minPrice, max),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScaleEnd extends StatelessWidget {
  final String text;

  const _ScaleEnd(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: context.colors.textPrimary,
      ),
    );
  }
}
