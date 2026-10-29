import 'package:tilomnov/features/property/data/models/map_property_filter.dart';
import 'package:tilomnov/features/property/presentation/property_labels.dart';
import 'package:tilomnov/features/property/utils/property_format.dart';
import 'package:tilomnov/l10n/generated/app_localizations.dart';

/// One line naming what a saved search looks for, e.g.
/// "House · For sale · $50K–$200K · 2 keywords". "Any listing" when nothing
/// narrows it.
String savedSearchSummary(AppLocalizations l10n, MapPropertyFilter filter) {
  String money(double value) => PropertyFormat.shortMoney(value);
  final parts = [
    if (filter.propertyType case final type?) propertyValueLabel(l10n, type),
    if (filter.isForSale) l10n.filterForSale,
    if (filter.isForRent) l10n.filterForRent,
    switch ((filter.minPrice, filter.maxPrice)) {
      (final min?, final max?) => '${money(min)}–${money(max)}',
      (final min?, null) => '≥ ${money(min)}',
      (null, final max?) => '≤ ${money(max)}',
      _ => null,
    },
    switch ((filter.minSize, filter.maxSize)) {
      (final min?, final max?) =>
        '${PropertyFormat.size(min)}–${PropertyFormat.size(max)} m²',
      (final min?, null) => '≥ ${PropertyFormat.size(min)} m²',
      (null, final max?) => '≤ ${PropertyFormat.size(max)} m²',
      _ => null,
    },
    if (filter.keywords.isNotEmpty)
      l10n.savedSearchKeywords(filter.keywords.length),
  ].whereType<String>();
  return parts.isEmpty ? l10n.savedSearchAnyListing : parts.join(' · ');
}
