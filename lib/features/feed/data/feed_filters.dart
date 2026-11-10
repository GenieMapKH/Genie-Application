import 'package:flutter/foundation.dart';

enum FeedSort { newest, top, priceLow, priceHigh }

@immutable
class FeedFilters {
  final FeedSort sort;
  final String? propertyType;
  final DateTime? fromDate;
  final DateTime? toDate;
  final double? minPrice;
  final double? maxPrice;

  const FeedFilters({
    this.sort = FeedSort.newest,
    this.propertyType,
    this.fromDate,
    this.toDate,
    this.minPrice,
    this.maxPrice,
  });

  int get activeCount =>
      (sort == FeedSort.newest ? 0 : 1) +
      (propertyType == null ? 0 : 1) +
      (fromDate == null && toDate == null ? 0 : 1) +
      (minPrice == null && maxPrice == null ? 0 : 1);

  bool get isDefault => activeCount == 0;

  bool get priceRangeReversed =>
      minPrice != null && maxPrice != null && minPrice! > maxPrice!;

  bool get pricesValid => [minPrice, maxPrice].every(
    (price) =>
        price == null ||
        (price.isFinite && price >= 0 && price <= 9999999999.99),
  );

  Map<String, Object> toQuery() => {
    'sort': sort.name,
    'propertyType': ?propertyType,
    if (fromDate case final from?)
      'since': DateTime(
        from.year,
        from.month,
        from.day,
      ).toUtc().toIso8601String(),
    // The API's upper bound is exclusive; include all of the selected last day.
    if (toDate case final to?)
      'until': DateTime(
        to.year,
        to.month,
        to.day + 1,
      ).toUtc().toIso8601String(),
    'minPrice': ?minPrice,
    'maxPrice': ?maxPrice,
  };
}
